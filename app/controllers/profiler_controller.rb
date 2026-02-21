# typed: false

class ProfilerController < ApplicationController
  def index
    entries = profiler_entries
    html = build_html(entries)
    render plain: html, content_type: "text/html", status: :ok
  end

  private

  def profiler_entries
    store = Rack::MiniProfiler.config.storage_instance
    cache = store.instance_variable_get(:@timer_struct_cache)
    return [] unless cache.is_a?(Hash)

    cache.values
  end

  def build_html(entries)
    rows = entries
      .sort_by { |e| e[:started_at] || 0 }
      .reverse
      .first(200)
      .map { |e| build_row(e) }
      .join

    <<~HTML
      <!DOCTYPE html>
      <html>
        <head>
          <meta charset="utf-8">
          <title>MiniProfiler Results</title>
          <style>
            body { font-family: Arial, sans-serif; padding: 20px; }
            table { border-collapse: collapse; width: 100%; }
            th, td { border: 1px solid #ddd; padding: 8px; font-size: 12px; }
            th { background: #f4f4f4; text-align: left; }
            .muted { color: #666; }
          </style>
        </head>
        <body>
          <h1>MiniProfiler Results</h1>
          <p class="muted">Showing last #{entries.size} entries (max 200).</p>
          <table>
            <thead>
              <tr>
                <th>Time</th>
                <th>Method</th>
                <th>Path</th>
                <th>Duration (ms)</th>
                <th>SQL</th>
                <th>Details</th>
              </tr>
            </thead>
            <tbody>
              #{rows}
            </tbody>
          </table>
        </body>
      </html>
    HTML
  end

  def build_row(entry)
    time = Time.at((entry[:started_at] || 0) / 1000.0).strftime("%Y-%m-%d %H:%M:%S")
    method = entry[:request_method] || "-"
    path = entry[:request_path] || entry[:name] || "-"
    root = entry[:root] if entry.respond_to?(:[])
    duration = (root && root[:duration_milliseconds]) || entry[:duration_milliseconds] || 0
    sql = entry[:sql_count] || 0
    id = entry[:id]
    details = id ? "/mini-profiler-resources/results?id=#{ERB::Util.url_encode(id)}" : "#"
    details_full = id ? "#{details}&pp=full-backtrace" : "#"

    <<~HTML
      <tr>
        <td>#{ERB::Util.html_escape(time)}</td>
        <td>#{ERB::Util.html_escape(method)}</td>
        <td>#{ERB::Util.html_escape(path)}</td>
        <td>#{ERB::Util.html_escape(duration.to_s)}</td>
        <td>#{ERB::Util.html_escape(sql.to_s)}</td>
        <td><a href="#{details}">open</a> | <a href="#{details_full}">full backtrace</a></td>
      </tr>
    HTML
  end
end
