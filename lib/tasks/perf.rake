require "open3"

module PerfHelpers
  def self.ensure_wrk!(wrk_bin)
    unless system("command -v #{wrk_bin} > /dev/null 2>&1")
      abort("wrk not found. Install wrk or set WRK_BIN to its path.")
    end
  end

  def self.parse_mem_to_mb(mem_str)
    return nil if mem_str.nil? || mem_str.strip.empty?

    value, unit = mem_str.strip.match(/\A([\d\.]+)\s*([KMG]iB|[KMG]B|B)\z/)&.captures
    return nil unless value && unit

    value = value.to_f
    case unit
    when "B"
      value / (1024.0 * 1024.0)
    when "KB", "KiB"
      value / 1024.0
    when "MB", "MiB"
      value
    when "GB", "GiB"
      value * 1024.0
    else
      nil
    end
  end

  def self.docker_mem_sample(container_name)
    mem = `docker stats --no-stream --format "{{.MemUsage}}" #{container_name}`.split("/").first.to_s.strip
    parse_mem_to_mb(mem)
  end

  def self.ps_mem_sample(pid)
    rss_kb = `ps -o rss= -p #{pid}`.to_i
    return nil if rss_kb <= 0

    rss_kb / 1024.0
  end

  def self.run_wrk(label:, url:, wrk_bin:, duration:, connections:, threads:, method:, body:, headers:, script_path:, server_pid:, docker_container:, sample_interval:)
    env = {
      "WRK_METHOD" => method,
      "WRK_BODY" => body,
      "WRK_HEADERS" => headers,
    }

    cmd = [
      wrk_bin,
      "-t#{threads}",
      "-c#{connections}",
      "-d#{duration}",
      "-s",
      script_path,
      url,
    ]

    samples = []
    sampler = nil

    if docker_container
      sampler = Thread.new do
        loop do
          mb = docker_mem_sample(docker_container)
          samples << mb if mb
          sleep sample_interval
        end
      end
    elsif server_pid
      sampler = Thread.new do
        loop do
          mb = ps_mem_sample(server_pid)
          samples << mb if mb
          sleep sample_interval
        end
      end
    end

    stdout, stderr, status = Open3.capture3(env, *cmd)
    sampler&.kill

    unless status.success?
      warn(stderr) unless stderr.empty?
      abort("wrk failed for #{label}")
    end

    reqs_sec = stdout[/Requests\/sec:\s+([\d\.]+)/, 1]&.to_f
    latency = stdout[/Latency\s+([\d\.]+[a-z]+)/, 1]

    mem_stats = nil
    if samples.any?
      avg_mb = samples.sum.to_f / samples.size
      max_mb = samples.max
      mem_stats = {
        avg_mb: avg_mb.round(2),
        max_mb: max_mb.round(2),
        samples: samples.size,
      }
    end

    {
      label: label,
      url: url,
      reqs_sec: reqs_sec,
      latency: latency,
      mem: mem_stats,
      raw: stdout,
    }
  end
end

namespace :perf do
  desc "Compare v1/v2 endpoints with wrk (throughput + memory sampling)"
  task :compare do
    wrk_bin = ENV.fetch("WRK_BIN", "wrk")
    PerfHelpers.ensure_wrk!(wrk_bin)

    base_url = ENV.fetch("BASE_URL", "http://localhost:3000")
    base_url_v1 = ENV.fetch("BASE_URL_V1", base_url)
    base_url_v2 = ENV.fetch("BASE_URL_V2", base_url)
    v1_path = ENV.fetch("V1_PATH", "/api/v1/registrations")
    v2_path = ENV.fetch("V2_PATH", "/api/v2/registrations")

    duration = ENV.fetch("DURATION", "10s")
    connections = ENV.fetch("CONNECTIONS", "20")
    threads = ENV.fetch("THREADS", "4")
    method = ENV.fetch("METHOD", "POST")
    warmup = ENV.fetch("WARMUP", "5s")
    cooldown = ENV.fetch("COOLDOWN", "2").to_f
    order = ENV.fetch("ORDER", "alternate") # alternate|v1_first|v2_first

    body = ENV.fetch(
      "BODY",
      '{"user":{"email":"perf@example.com","password":"password","password_confirmation":"password"}}'
    )
    headers = ENV.fetch("HEADERS", "Content-Type: application/json")
    server_pid = ENV["SERVER_PID"]
    docker_container = ENV["DOCKER_CONTAINER"]
    docker_service = ENV["DOCKER_SERVICE"]
    docker_container_v1 = ENV["DOCKER_CONTAINER_V1"]
    docker_container_v2 = ENV["DOCKER_CONTAINER_V2"]
    docker_service_v1 = ENV["DOCKER_SERVICE_V1"]
    docker_service_v2 = ENV["DOCKER_SERVICE_V2"]
    sample_interval = ENV.fetch("MEM_SAMPLE_INTERVAL", "0.5").to_f

    script_path = File.expand_path("scripts/perf/wrk_request.lua", Dir.pwd)

    puts "Running wrk against:"
    puts "  v1: #{base_url_v1}#{v1_path}"
    puts "  v2: #{base_url_v2}#{v2_path}"
    puts "  method=#{method} duration=#{duration} threads=#{threads} connections=#{connections}"
    puts "  server_pid=#{server_pid || "not set"}"
    if docker_container_v1.nil? && docker_service_v1
      docker_container_v1 = `docker ps --filter "name=#{docker_service_v1}" --format "{{.Names}}" | head -n 1`.strip
    end
    if docker_container_v2.nil? && docker_service_v2
      docker_container_v2 = `docker ps --filter "name=#{docker_service_v2}" --format "{{.Names}}" | head -n 1`.strip
    end
    if docker_container.nil? && docker_service
      docker_container = `docker ps --filter "name=#{docker_service}" --format "{{.Names}}" | head -n 1`.strip
    end

    puts "  docker_container_v1=#{docker_container_v1 || docker_container || "not set"}"
    puts "  docker_container_v2=#{docker_container_v2 || docker_container || "not set"}"

    endpoints = [
      { key: "v1", url: "#{base_url_v1}#{v1_path}", docker_container: docker_container_v1 || docker_container },
      { key: "v2", url: "#{base_url_v2}#{v2_path}", docker_container: docker_container_v2 || docker_container },
    ]
    if order == "v2_first"
      endpoints.reverse!
    elsif order == "alternate"
      endpoints.rotate!
    end

    endpoints.each do |ep|
      PerfHelpers.run_wrk(
        label: "#{ep[:key]}-warmup",
        url: ep[:url],
        wrk_bin: wrk_bin,
        duration: warmup,
        connections: connections,
        threads: threads,
        method: method,
        body: body,
        headers: headers,
        script_path: script_path,
        server_pid: server_pid,
        docker_container: ep[:docker_container],
        sample_interval: sample_interval
      )
    end

    results = {}
    endpoints.each do |ep|
      results[ep[:key]] = PerfHelpers.run_wrk(
        label: ep[:key],
        url: ep[:url],
        wrk_bin: wrk_bin,
        duration: duration,
        connections: connections,
        threads: threads,
        method: method,
        body: body,
        headers: headers,
        script_path: script_path,
        server_pid: server_pid,
        docker_container: ep[:docker_container],
        sample_interval: sample_interval
      )
      sleep cooldown if cooldown.positive?
    end
    v1 = results["v1"]
    v2 = results["v2"]

    puts "\nResults"
    [v1, v2].each do |r|
      puts "- #{r[:label]}: #{r[:reqs_sec]} req/s, latency #{r[:latency]}"
      if r[:mem]
        puts "  memory: avg #{r[:mem][:avg_mb]} MB, max #{r[:mem][:max_mb]} MB (#{r[:mem][:samples]} samples)"
      end
    end

    if v1[:reqs_sec] && v2[:reqs_sec]
      delta = (v2[:reqs_sec] - v1[:reqs_sec]).round(2)
      puts "\nThroughput delta (v2 - v1): #{delta} req/s"
    end
  end

  desc "Run a small matrix of perf variations and save markdown reports"
  task :matrix do
    wrk_bin = ENV.fetch("WRK_BIN", "wrk")
    PerfHelpers.ensure_wrk!(wrk_bin)

    base_url = ENV.fetch("BASE_URL", "http://localhost:3000")
    v1_path = ENV.fetch("V1_PATH", "/api/v1/registrations")
    v2_path = ENV.fetch("V2_PATH", "/api/v2/registrations")

    durations = (ENV["DURATIONS"] || "10s,30s").split(",")
    connections_list = (ENV["CONNECTIONS_LIST"] || "20,50").split(",")
    threads_list = (ENV["THREADS_LIST"] || "4").split(",")
    warmup = ENV.fetch("WARMUP", "5s")
    cooldown = ENV.fetch("COOLDOWN", "2").to_f
    order = ENV.fetch("ORDER", "alternate") # alternate|v1_first|v2_first

    method = ENV.fetch("METHOD", "POST")
    body = ENV.fetch(
      "BODY",
      '{"user":{"email":"perf@example.com","password":"password","password_confirmation":"password"}}'
    )
    headers = ENV.fetch("HEADERS", "Content-Type: application/json")
    server_pid = ENV["SERVER_PID"]
    docker_container = ENV["DOCKER_CONTAINER"]
    docker_service = ENV["DOCKER_SERVICE"]
    sample_interval = ENV.fetch("MEM_SAMPLE_INTERVAL", "0.5").to_f

    script_path = File.expand_path("scripts/perf/wrk_request.lua", Dir.pwd)

    if docker_container.nil? && docker_service
      docker_container = `docker ps --filter "name=#{docker_service}" --format "{{.Names}}" | head -n 1`.strip
    end

    results_dir = File.join(Dir.pwd, "reports")
    Dir.mkdir(results_dir) unless Dir.exist?(results_dir)

    date_stamp = Time.now.strftime("%Y%m%d-%H%M%S")
    index_path = File.join(results_dir, "perf_matrix_#{date_stamp}.md")
    index_lines = []
    index_lines << "# Perf Matrix Report"
    index_lines << ""
    index_lines << "- Date: #{Time.now.strftime("%Y-%m-%d %H:%M:%S")}"
    index_lines << "- Base URL: `#{base_url}`"
    index_lines << "- v1: `#{v1_path}`"
    index_lines << "- v2: `#{v2_path}`"
    index_lines << "- Method: `#{method}`"
    index_lines << "- Docker container: `#{docker_container}`"
    index_lines << ""
    index_lines << "## Runs"
    index_lines << ""

    durations.each do |duration|
      connections_list.each do |connections|
        threads_list.each do |threads|
          label = "d#{duration}-c#{connections}-t#{threads}"
          report_path = File.join(results_dir, "perf_#{label}_#{date_stamp}.md")

          endpoints = [
            { key: "v1", url: "#{base_url}#{v1_path}" },
            { key: "v2", url: "#{base_url}#{v2_path}" },
          ]
          if order == "v2_first"
            endpoints.reverse!
          elsif order == "alternate"
            endpoints.rotate!
          end

          endpoints.each do |ep|
            PerfHelpers.run_wrk(
              label: "#{ep[:key]}-warmup",
              url: ep[:url],
              wrk_bin: wrk_bin,
              duration: warmup,
              connections: connections,
              threads: threads,
              method: method,
              body: body,
              headers: headers,
              script_path: script_path,
              server_pid: server_pid,
              docker_container: docker_container,
              sample_interval: sample_interval
            )
          end

          results = {}
          endpoints.each do |ep|
            results[ep[:key]] = PerfHelpers.run_wrk(
              label: ep[:key],
              url: ep[:url],
              wrk_bin: wrk_bin,
              duration: duration,
              connections: connections,
              threads: threads,
              method: method,
              body: body,
              headers: headers,
              script_path: script_path,
              server_pid: server_pid,
              docker_container: docker_container,
              sample_interval: sample_interval
            )
            sleep cooldown if cooldown.positive?
          end
          v1 = results["v1"]
          v2 = results["v2"]

          File.write(report_path, <<~MD)
            # Perf Run: #{label}

            - Date: #{Time.now.strftime("%Y-%m-%d %H:%M:%S")}
            - Duration: #{duration}
            - Connections: #{connections}
            - Threads: #{threads}
            - Method: #{method}
            - Base URL: #{base_url}
            - v1 Path: #{v1_path}
            - v2 Path: #{v2_path}
            - Docker container: #{docker_container}

            ## Results

            | Endpoint | Req/s | Latency | Memory Avg (MB) | Memory Max (MB) | Samples |
            |---|---:|---:|---:|---:|---:|
            | v1 | #{v1[:reqs_sec]} | #{v1[:latency]} | #{v1.dig(:mem, :avg_mb)} | #{v1.dig(:mem, :max_mb)} | #{v1.dig(:mem, :samples)} |
            | v2 | #{v2[:reqs_sec]} | #{v2[:latency]} | #{v2.dig(:mem, :avg_mb)} | #{v2.dig(:mem, :max_mb)} | #{v2.dig(:mem, :samples)} |

            ## Raw wrk output

            ### v1
            ```
            #{v1[:raw]}
            ```

            ### v2
            ```
            #{v2[:raw]}
            ```
          MD

          index_lines << "- `#{label}`: `#{File.basename(report_path)}`"
        end
      end
    end

    File.write(index_path, index_lines.join("\n") + "\n")
    puts "Wrote matrix report index: #{index_path}"
  end
end
