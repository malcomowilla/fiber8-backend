class ImportSubscribersJob < ApplicationJob
  queue_as :default

  def perform(file_path, filename, account_id, job_id)
    account = Account.find(account_id)
    channel = "import_progress:#{account_id}:#{job_id}"

    ActsAsTenant.with_tenant(account) do
      rows = parse_file(file_path, filename)
      total = rows.length
      done  = 0
      errors   = []
      warnings = []

      broadcast(channel,
        type:    'progress',
        pct:     2,
        done:    0,
        total:   total,
        phase:   'parsing',
        message: "Parsed #{total} rows — starting import…"
      )

      rows.each_with_index do |row, idx|
        phone   = row['phone']&.to_s&.strip
        name    = row['name']&.to_s&.strip
        package = row['package']&.to_s&.strip

        # ── Validation ───────────────────────────────────────────────────
        if phone.blank? || name.blank?
          warnings << { row: idx + 2, message: "Skipped — missing name or phone" }

          # broadcast every batch even if it's a skip
          broadcast_batch(channel, idx, total, done, errors, warnings, name) if should_broadcast?(idx, total)
          next
        end

        # ── Upsert subscriber ────────────────────────────────────────────
        begin
          subscriber = Subscriber.find_or_initialize_by(
            phone_number: phone,
            account:      account
          )

          pkg = Package.find_by(name: package, account: account) if package.present?

          subscriber.assign_attributes(
            name:      name,
            address:   row['address']&.to_s&.strip,
            id_number: row['id_number']&.to_s&.strip,
          )
          subscriber.package         = pkg if pkg
          subscriber.expiration_date = parse_date(row['expiration_date']) if row['expiration_date'].present?

          subscriber.save!
          done += 1

        rescue ActiveRecord::RecordInvalid => e
          errors << { row: idx + 2, message: e.record.errors.full_messages.join(', ') }
        rescue => e
          errors << { row: idx + 2, message: e.message }
        end

        # broadcast every 5 rows (always if small file)
        if should_broadcast?(idx, total)
          broadcast_batch(channel, idx, total, done, errors, warnings, name)
        end
      end

      # ── Final broadcast ──────────────────────────────────────────────────
      broadcast(channel,
        type:     'complete',
        pct:      100,
        done:     done,
        total:    total,
        phase:    'done',
        message:  "Done — #{done} imported, #{warnings.size} skipped, #{errors.size} errors.",
        errors:   errors,
        warnings: warnings
      )
    end

  rescue => e
    # catch anything that blows up before the loop (bad file, missing account, etc.)
    channel = "import_progress:#{account_id}:#{job_id}"
    broadcast(channel,
      type:    'error',
      message: "Import failed: #{e.message}"
    )
    Rails.logger.error "[ImportSubscribersJob] #{e.class}: #{e.message}\n#{e.backtrace.first(5).join("\n")}"

  ensure
    # always clean up the temp file
    FileUtils.rm_f(file_path) if file_path.present? && File.exist?(file_path.to_s)
  end

  private

  # broadcast every 5 rows, always on last row, always when file < 50 rows
  def should_broadcast?(idx, total)
    (idx + 1) % 5 == 0 || idx + 1 == total || total < 50
  end

  def broadcast_batch(channel, idx, total, done, errors, warnings, current_name)
    pct = ((done.to_f / [total, 1].max) * 95).round + 2
    broadcast(channel,
      type:        'progress',
      pct:         [pct, 97].min,   # save 100 for the 'complete' event
      done:        done,
      total:       total,
      phase:       'creating',
      message:     "Row #{idx + 2} of #{total} — #{current_name}",
      errors:      errors.last(10),   # send only the latest batch to avoid huge payloads
      warnings:    warnings.last(10)
    )
  end

  def broadcast(channel, payload)
    ActionCable.server.broadcast(channel, payload)
  end

  def parse_file(path, filename)
    ext = File.extname(filename.to_s).downcase

    if ext == '.csv'
      CSV.read(path, headers: true, encoding: 'UTF-8').map(&:to_h)
    elsif ['.xlsx', '.xls'].include?(ext)
      xlsx    = Roo::Spreadsheet.open(path)
      headers = xlsx.row(1).map { |h| h&.to_s&.strip&.downcase&.gsub(/\s+/, '_') }
      (2..xlsx.last_row).map { |i| headers.zip(xlsx.row(i)).to_h }
    else
      raise "Unsupported file type: #{ext}. Use CSV or Excel."
    end
  end

  def parse_date(raw)
    return nil if raw.blank?
    Date.parse(raw.to_s)
  rescue ArgumentError
    nil
  end
end

