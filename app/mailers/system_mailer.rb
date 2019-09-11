class SystemMailer < ActionMailer::Base
  default :to => "michael.andersen.85@gmail.com",
          :from => "jnlager@gmail.com"

  def backup_mail(filename, backup_time_utc)
    attachments[filename] = File.read(filename)
    @backup_time_utc = backup_time_utc
    mail({
      :to      => "michael.andersen.85@gmail.com",
      :subject => "Backup - #{l backup_time_utc}"
    })
  end

end
