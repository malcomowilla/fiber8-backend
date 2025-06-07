# app/workers/fcm_notification_worker.rb
class FcmNotificationWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default

  require 'fcm'
  require 'rest-client'
  require 'json'

  def perform(fcm_token)
    Rails.logger.info "[Sidekiq] FcmNotificationWorker started with token: #{fcm_token}"

    Account.find_each do |tenant|
      ActsAsTenant.with_tenant(tenant) do
        scopes = ['https://www.googleapis.com/auth/firebase.messaging']
 json_key_data = File.read(File.expand_path("/home/aitechs-push-notifications-f504158d59ac.json"))

        json_key_io = StringIO.new(json_key_data)

        credentials = Google::Auth::ServiceAccountCredentials.make_creds(
          json_key_io: json_key_io,
          scope: scopes
        )

        access_token = credentials.fetch_access_token!['access_token']

        payload = {
          message: {
            token: fcm_token,
            notification: {
              title:  "upcoming event 👉",
              body:   'test event',
            },
            webpush: {
              fcm_options: {
                link: "http://localhost:5173"
              }
            },
            data: {
              story_id: 'story_12345'
            }
          }
        }.to_json

        begin
          response = RestClient.post(
            "https://fcm.googleapis.com/v1/projects/aitechs-push-notifications/messages:send",
            payload,
            { Authorization: "Bearer #{access_token}", content_type: :json, accept: :json }
          )
          Rails.logger.info "[Sidekiq] FCM response: #{response.body}"
        rescue RestClient::ExceptionWithResponse => e
          Rails.logger.error "[Sidekiq] FCM request failed: #{e.response}"
        end
      end
    end
  end
end
