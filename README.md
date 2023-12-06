# GDAP-quarantine-notifications
Manage mail quarantine settings and notification address for GDAP customers.

The standard quarantine policy alerts the group TenantAdmins, consisting of all the global admins, when a user requests a message to be released from quarantine.

The standard Protection Alert which handles these notifications can only be customized in the GUI, not through powershell.
It is possible to create a new Protection Alert with a custom recipient but only if the tenant has at least one E5 license assigned.

To circumvent this, you can create a shared mailbox and add the role of global admin, then disable the login for the associated user of the shared mailbox and hide it from the glboal address list.
Also a policy is created to allow forwarding to external recipients but only for the new shared mailbox.
After setting up a forwarding recipient, all the notifications go to the address specified in the forwarding.

The script creates a new quarantine policy where end users are allowed to preview messages in quarantine and request a release.
It then edits the standard inbound spam filter to send all high confidence phishing and spam mail to the quarantine.

For creating session connections delegated access is used, a GDAP relationship with the global admin role to the customer is needed.