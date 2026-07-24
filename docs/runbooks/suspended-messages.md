# Runbook: Suspended interoperability messages

**Alerts:** `IRISSuspendedMessages`, `IRISInteroperabilityErrorsRising`
**Severity:** warning

## Impact

One or more messages are suspended and will not be processed until a human intervenes.
Suspended messages usually indicate a message that failed processing and was held for
review rather than discarded — clinical data may be stuck.

## Verification

In Prometheus: `iris_interop_messages_suspended{gateway="nginx"}`.

In the Management Portal: Interoperability → View → Message Viewer, filter by status
*Suspended*.

## Immediate containment

- Review each suspended message and its error.
- Fix the underlying cause (bad data, transformation error, downstream rejection).
- Resubmit or delete the message once resolved.

## Root-cause checks

- Data-quality problem in the source feed.
- Transformation/routing rule defect.
- Downstream system rejecting valid messages.

## Recovery

After suspended messages are resubmitted or cleared,
`iris_interop_messages_suspended` returns to 0 and the alert resolves. The lab's
`restore-demo.sh` resumes demo-suspended headers automatically.

## Escalation

Escalate to the interface/application owner when the root cause is a message-content
or downstream defect.

## Prevention

- Monitor `iris_interop_messages_errored` trends to catch problems before messages
  suspend.
- Add validation earlier in the pipeline.
