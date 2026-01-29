require "open3"

namespace :perf do
  desc "Compare v1/v2 endpoints with wrk (throughput + memory sampling)"
  task :compare do
    wrk_bin = ENV.fetch("WRK_BIN", "wrk")
    unless system("command -v #{wrk_bin} > /dev/null 2>&1")
      abort("wrk not found. Install wrk or set WRK_BIN to its path.")
    end

    base_url = ENV.fetch("BASE_URL", "http://localhost:3000")
    v1_path = ENV.fetch("V1_PATH", "/api/v1/registrations")
    v2_path = ENV.fetch("V2_PATH", "/api/v2/registrations")

    duration = ENV.fetch("DURATION", "10s")
    connections = ENV.fetch("CONNECTIONS", "20")
    threads = ENV.fetch("THREADS", "4")
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

    def parse_mem_to_mb(mem_str)
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

    def docker_mem_sample(container_name)
      mem = `docker stats --no-stream --format "{{.MemUsage}}" #{container_name}`.split("/").first.to_s.strip
      parse_mem_to_mb(mem)
    end

    def ps_mem_sample(pid)
      rss_kb = `ps -o rss= -p #{pid}`.to_i
      return nil if rss_kb <= 0

      rss_kb / 1024.0
    end

    def run_wrk(label, url, wrk_bin, duration, connections, threads, method, body, headers, script_path, server_pid, docker_container, sample_interval)
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

    puts "Running wrk against:"
    puts "  v1: #{base_url}#{v1_path}"
    puts "  v2: #{base_url}#{v2_path}"
    puts "  method=#{method} duration=#{duration} threads=#{threads} connections=#{connections}"
    puts "  server_pid=#{server_pid || "not set"}"
    if docker_container.nil? && docker_service
      docker_container = `docker ps --filter "name=#{docker_service}" --format "{{.Names}}" | head -n 1`.strip
    end

    puts "  docker_container=#{docker_container || "not set"}"

    v1 = run_wrk("v1", "#{base_url}#{v1_path}", wrk_bin, duration, connections, threads, method, body, headers, script_path, server_pid, docker_container, sample_interval)
    v2 = run_wrk("v2", "#{base_url}#{v2_path}", wrk_bin, duration, connections, threads, method, body, headers, script_path, server_pid, docker_container, sample_interval)

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
end
