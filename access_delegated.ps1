###GDAP relationship to customer tenant, including GA role, must be established beforehand!###
$CustomerTenantId = ''
$CustomerDomain = ''
$AddressToBeNotified = ''
$QuarantinePolicyName = ''
Connect-ExchangeOnline -DelegatedOrganization $CustomerDomain

$mName = ''
$m = $mName + "@" + $CustomerDomain
###Account will be disabled afterwards!###
$tempPassword = (ConvertTo-SecureString -String "StandardAccountWillBeDisabled!2345" -AsPlainText -Force)

Enable-OrganizationCustomization -Confirm:$false

$usermbxs = (Get-EXOMailbox).UserPrincipalName

New-MailContact -Name $AddressToBeNotified -ExternalEmailAddress $AddressToBeNotified

###Check if shared mailbox already exists, if not create it###
if (!($usermbxs -contains $m)){
    Write-Host "Shared MB doesn't exist yet"
    New-Mailbox -MicrosoftOnlineServicesID $m -Name sgngAdminAlerts -Password $tempPassword
}
###Turn mailbox into type shared, forward all mail to external address, hide from GAL###
Set-Mailbox -Identity $m -Type Shared
Set-Mailbox -Identity $m -ForwardingAddress $AddressToBeNotified
Set-Mailbox -Identity $m -HiddenFromAddressListsEnabled $true

###Sets Recipient message access to "Limited access"##
###Microsoft documentation: https://learn.microsoft.com/en-us/powershell/module/exchange/new-quarantinepolicy?view=exchange-ps###
New-QuarantinePolicy -Name $QuarantinePolicyName -EndUserQuarantinePermissionsValue 27 -ESNEnabled $true

###Sets standard inbound spam filter policy to send high confidence spam and phish to newly created quarantine###
Set-HostedContentFilterPolicy -Identity Default -HighConfidencePhishAction Quarantine -HighConfidencePhishQuarantineTag SGNGQuarantinePolicy -HighConfidenceSpamAction Quarantine -HighConfidenceSpamQuarantineTag SGNGQuarantinePolicy

###Creates new outbound spam filter policy and rule to allow forwarding to exteral recipients###
$outboundPolicyName = ''''
New-HostedOutboundSpamFilterPolicy -Name $outboundPolicyName -AutoForwardingMode On

###Creates new outbound spam filter rule to allow forwarding to exteral recipients but only from our new shared mailbox###
$outboundRuleName = ''
New-HostedOutboundSpamFilterRule -Name $outboundRuleName -HostedOutboundSpamFilterPolicy $outboundPolicyName -From $m

###Gives the shared mailbox Global Administrator role so it will be a member of TenantAdmins###
Connect-AzureAD -TenantId $CustomerTenantId
$roleName = "Global Administrator"
$userName= $m
$role = Get-AzureADDirectoryRole | Where {$_.displayName -eq $roleName}
if ($role -eq $null) {
    $roleTemplate = Get-AzureADDirectoryRoleTemplate | Where {$_.displayName -eq $roleName}
    Enable-AzureADDirectoryRole -RoleTemplateId $roleTemplate.ObjectId
    $role = Get-AzureADDirectoryRole | Where {$_.displayName -eq $roleName}
}
Add-AzureADDirectoryRoleMember -ObjectId $role.ObjectId -RefObjectId (Get-AzureADUser | Where {$_.UserPrincipalName -eq $userName}).ObjectID


###New-ProtectionAlert can only be created if the tenant has an E5 license!###

#Connect-IPPSSession -UserPrincipalName 'automations@yourcompany.com' -DelegatedOrganization $CustomerDomain -AzureADAuthorizationEndpointUri 'https://login.microsoftonline.com/common'
#New-ProtectionAlert -Name "Quarantine Release request" -Category Others -ThreatType Activity -Operation QuarantineReleaseRequest -NotifyUser $AddressToBeNotified -AggregationType None -Confirm:$false
