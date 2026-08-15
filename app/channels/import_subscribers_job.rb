class ImportSubscribersJob < ApplicationJob
  queue_as :default

  def perform(file_path, filename, account_id, job_id,
              use_auto_username, use_auto_password, prefix, minimum_digits)

    account = Account.find(account_id)
    channel = "import_progress:#{account_id}:#{job_id}"

    ActsAsTenant.with_tenant(account) do
      rows  = parse_file(file_path, filename)
      total = rows.length
      done  = 0
      errors   = []
      warnings = []

      broadcast(channel, type: 'progress', pct: 2, done: 0, total: total,
                phase: 'parsing', message: "Parsed #{total} rows — starting import…")

      rows.each_with_index do |row, idx|
        normalized = row.to_h
                        .transform_keys { |k| k.to_s.downcase.strip.gsub(/\s+/, '_') }
                        .reject { |k, _| k.blank? }
        normalized.delete('action')
        normalized.delete('id')

        begin
          subscriber = Subscriber.new(normalized)

          # same ref_no logic as your original action
          if prefix && minimum_digits
            subscriber.ref_no ||=
              "#{prefix}#{subscriber.sequence_number.to_s.rjust(minimum_digits, '0')}"
          end

          subscriber.ppoe_username = subscriber.ref_no if use_auto_username
          subscriber.ppoe_password = subscriber.ref_no if use_auto_password

          if subscriber.valid?
            subscriber.save!
            done += 1
          else
            errors << { row: idx + 2, message: subscriber.errors.full_messages.join(', ') }
          end

        rescue => e
          errors << { row: idx + 2, message: e.message }
        end

        if should_broadcast?(idx, total)
          pct = [((done.to_f / [total, 1].max) * 95).round + 2, 97].min
          broadcast(channel,
            type:     'progress',
            pct:      pct,
            done:     done,
            total:    total,
            phase:    'creating',
            message:  "Row #{idx + 2} of #{total}",
            errors:   errors.last(10),
            warnings: warnings.last(10)
          )
        end
      end

      broadcast(channel,
        type:     'complete',
        pct:      100,
        done:     done,
        total:    total,
        phase:    'done',
        message:  "Done — #{done} imported, #{errors.size} errors.",
        errors:   errors,
        warnings: warnings
      )
    end

  rescue => e
    channel = "import_progress:#{account_id}:#{job_id}"
    broadcast(channel, type: 'error', message: "Import failed: #{e.message}")
    Rails.logger.error "[ImportSubscribersJob] #{e.class}: #{e.message}"
  ensure
    FileUtils.rm_f(file_path) if file_path.present? && File.exist?(file_path.to_s)
  end

  private

  def should_broadcast?(idx, total)
    (idx + 1) % 5 == 0 || idx + 1 == total || total < 50
  end

  def broadcast(channel, payload)
    ActionCable.server.broadcast(channel, payload)
  end

  def parse_file(path, filename)
    ext = File.extname(filename.to_s).downcase
    if ext == '.csv'
      content = File.read(path).encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
      content.sub!("\uFEFF", '')  # same BOM removal as your original
      CSV.parse(content, headers: true).map(&:to_h)
    else
      xlsx    = Roo::Spreadsheet.open(path)
      headers = xlsx.row(1).map { |h| h&.to_s&.strip&.downcase&.gsub(/\s+/, '_') }
      (2..xlsx.last_row).map { |i| headers.zip(xlsx.row(i)).to_h }
    end
  end
end