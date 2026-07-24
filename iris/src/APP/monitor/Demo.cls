Include (Ensemble, %occStatus)

/// Helper methods that create controlled, reversible interoperability failure
/// scenarios for the monitoring / alerting lab. Not for production use.
///
/// Invoked from the shell scripts in <b>demo/</b> via <code>iris session</code>.
Class APP.monitor.Demo
{

/// Business operation used to demonstrate a queue backlog.
Parameter TARGETOP = "to EMR - FILE";

/// Disable an operation and inject queued messages so its queue depth grows.
ClassMethod QueueBacklog(pCount As %Integer = 150) As %Status
{
    // Best effort: iris_interop_queued only reports hosts that have a queue-count
    // alert configured, so try to enable it on the target host.
    try { do ..SetQueueCountAlert(..#TARGETOP, 1) } catch { }

    // Disable the operation so injected messages accumulate in its queue.
    do ##class(Ens.Director).EnableConfigItem(..#TARGETOP, 0, 1)

    set tSC = ##class(Ens.Director).CreateBusinessService("EnsLib.Testing.Service", .tService)
    if $$$ISERR(tSC) quit tSC
    for i = 1:1:pCount {
        set tReq = ##class(Ens.StringRequest).%New()
        set tReq.StringValue = "demo backlog message " _ i
        do tService.SendRequestAsync(..#TARGETOP, tReq)
    }
    write !, "Injected ", pCount, " messages into the queue for '", ..#TARGETOP, "'."
    quit $$$OK
}

/// Re-enable the target operation so it drains its queue.
ClassMethod ClearQueue() As %Status
{
    do ##class(Ens.Director).EnableConfigItem(..#TARGETOP, 1, 1)
    write !, "Re-enabled '", ..#TARGETOP, "'; the queue will drain."
    quit $$$OK
}

/// Mark the most recent pCount message headers as Suspended.
ClassMethod SuspendMessages(pCount As %Integer = 2) As %Status
{
    set tID = "", n = 0
    for {
        set tID = $order(^Ens.MessageHeaderD(tID), -1)
        quit:(tID = "")
        quit:(n '< pCount)
        set tHdr = ##class(Ens.MessageHeader).%OpenId(tID)
        continue:'$isobject(tHdr)
        set tHdr.Status = $$$eMessageStatusSuspended
        do tHdr.%Save()
        set n = n + 1
    }
    write !, "Suspended ", n, " message header(s)."
    quit $$$OK
}

/// Restore any Suspended message headers back to Completed.
ClassMethod ResumeMessages() As %Status
{
    set tID = "", n = 0
    for {
        set tID = $order(^Ens.MessageHeaderD(tID))
        quit:(tID = "")
        set tHdr = ##class(Ens.MessageHeader).%OpenId(tID)
        continue:'$isobject(tHdr)
        if tHdr.Status = $$$eMessageStatusSuspended {
            set tHdr.Status = $$$eMessageStatusCompleted
            do tHdr.%Save()
            set n = n + 1
        }
    }
    write !, "Resumed ", n, " message(s)."
    quit $$$OK
}

/// Best-effort: enable the queue-count alert on a business host so its queued
/// messages are reported by iris_interop_queued.
ClassMethod SetQueueCountAlert(pItem As %String, pValue As %Integer = 1) As %Status
{
    set tProd = ##class(Ens.Config.Production).%OpenId(##class(Ens.Director).GetActiveProductionName())
    quit:'$isobject(tProd) $$$OK
    for i = 1:1:tProd.Items.Count() {
        set tItem = tProd.Items.GetAt(i)
        if tItem.Name = pItem {
            do tItem.SetModifiedSetting("Host", "QueueCountAlert", pValue)
        }
    }
    do tProd.%Save()
    quit $$$OK
}

}
