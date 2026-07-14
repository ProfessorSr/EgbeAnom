# Email

Use this to set up SMTP email and send test emails.

## What Email Does Now

- The app can send through SMTP using the deployed email function.
- Customers can receive an invoice or order email after successful payment.
- Customers can receive emails when status changes to Processing, Label created, and Sent or Shipped.

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

## Before Trusting Email

- Save settings.
- Send one test email to a real inbox.
- Open the inbox and confirm it arrived.
- Then test a paid order email.

[Back to Admin Guide Home](./README.md)
