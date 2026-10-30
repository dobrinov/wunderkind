# The few pieces every email is built from, as inline styles — most mail
# clients drop <style> blocks — in the app's own colours: the primary button
# with the tactile edge the app's .button-primary has, a secondary in white,
# and the plain address under a button for a client that will not render it.
module EmailHelper
  BUTTON = "display:inline-block;padding:13px 20px;border-radius:12px;font-size:15px;font-weight:900;text-decoration:none;"
  PRIMARY = "background:#5048e5;color:#ffffff;box-shadow:0 3px 0 #3730a3;"
  SECONDARY = "background:#ffffff;color:#1f2133;border:1px solid #dcdce8;box-shadow:0 3px 0 #dcdce8;"

  def email_button(label, url, secondary: false)
    tag.p(style: "margin:20px 0 4px;") do
      link_to label, url, style: BUTTON + (secondary ? SECONDARY : PRIMARY)
    end
  end

  def email_fallback(url)
    tag.p(style: "margin:20px 0 0;padding-top:14px;border-top:1px solid #ececf4;font-size:13px;line-height:1.5;color:#5d5f78;") do
      safe_join([ t("mailers.button_fallback"), tag.br, link_to(url, url, style: "color:#4038ca;word-break:break-all;") ])
    end
  end
end
