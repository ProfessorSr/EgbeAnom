# Email

Use this to set up SMTP email and send test emails.

## What Email Does Now

- The app can send through SMTP using the deployed email function.
- Google/Gmail, GoDaddy, custom domain, and generic SMTP settings are supported.
- The admin Email page can manage more than one mailbox account.
- Each mailbox can sync its own inbox from the mail server.
- Email messages are not stored in the store database. Read and unread state is changed on the mail server when supported.
- Customers can receive an invoice or order email after successful payment.
- Customers can receive emails when status changes to Processing, Label created, and Sent or Shipped.
- Emails use the same clean style as invoices and pack lists.
- Email footers include support information, unsubscribe instructions, and the QR code.

## Provider Choices

- Choose Google or Gmail if the store uses a Gmail or Google Workspace mailbox.
- Choose GoDaddy if the mailbox is hosted at GoDaddy.
- Choose Generic if another email company gives you SMTP settings.

## What To Enter

- From name is the store name customers see.
- From email is the store email address.
- SMTP host and port come from the email provider.
- Username is usually the full email address.
- Password should usually be an app password, not the normal mailbox password.
- Use direct SSL only if the provider says to use SSL on that port. Gmail and GoDaddy usually use port 587 with direct SSL turned off.

## EgbeAnom Mailbox Settings

- Use these settings for collins.egbe@egbeanom.com and support@egbeanom.com.
- Username: use the full email address, such as collins.egbe@egbeanom.com or support@egbeanom.com.
- Password: use that email account password. Do not write the password in the book or in project files.
- Incoming server: mail.egbeanom.com.
- Recommended IMAP port: 993 with SSL/TLS.
- POP3 is available on port 995 with SSL/TLS, but IMAP is usually better because it syncs folders across devices.
- Outgoing SMTP server: mail.egbeanom.com.
- Recommended SMTP port: 465 with SSL/TLS.
- IMAP, POP3, and SMTP require authentication.
- Non-SSL ports exist but are not recommended: IMAP 143, POP3 110, and SMTP 587.

## Inbox

- The Email page includes an inbox for store email such as orders@egbeanom.com.
- Use the Mailbox dropdown to choose which account you are viewing.
- Use Sync inbox to pull recent messages for the selected mailbox into admin.
- Unread messages show in the Email badge after sync.
- Open a message to read it, mark it read or unread, or reply from the composer.

## Mailing Lists

- There are two mailing lists.
- Account customers can join from their profile or from the homepage mailing list card while logged in.
- Non-account visitors can join by entering only an email address.
- Use the mailing list recipient choices when sending group emails.
- Mass emails are sent one at a time so customers do not see each other addresses.

## Before Trusting Email

- Save settings.
- Send one test email to a real inbox.
- Open the inbox and confirm it arrived.
- Then test a paid order email.

[Back to Admin Guide Home](./README.md)
