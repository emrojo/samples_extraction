module ApplicationCable
  class Connection < ActionCable::Connection::Base # rubocop:todo Style/Documentation
    identified_by :current_user

    def connect
      # self.current_user = nil
      token = cookies.encrypted['_samples_extraction_session']['token']
      if token
        self.current_user = User.find_by(token: token)
        return if self.current_user
      end
      reject_unauthorized_connection
    end
  end
end
