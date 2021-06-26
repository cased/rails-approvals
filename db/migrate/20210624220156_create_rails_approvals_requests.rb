class CreateRailsApprovalsRequests < ActiveRecord::Migration[6.1]
  def change
    create_table :rails_approvals_requests do |t|
      t.integer :state, null: false, default: 102
      t.string :command, null: true
      t.text :reason, null: true
      t.string :requester, null: false

      # Responder
      t.string :responder, null: true
      t.datetime :responded_at, null: true, precision: 6

      # The timestamp necessary for rails-approvals to update the request
      # message.
      t.string :slack_channel_id, null: true
      t.string :slack_message_ts, null: true

      t.timestamps null: false, precision: 6
    end
  end
end
