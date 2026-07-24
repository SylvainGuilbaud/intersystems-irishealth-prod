Include (Ensemble, %occStatus)

/// Custom application metrics for the monitoring / alerting lab.
///
/// These metrics are exported through the standard <b>/api/monitor/metrics</b>
/// endpoint with the <b>app_</b> prefix (the PRODUCT parameter). They complement the
/// native <b>iris_interop_*</b> metrics enabled with
/// <code>##class(Ens.Util.Statistics).EnableSAMForNamespace()</code>.
///
/// Register once (per InterSystems IRIS upgrade) from the %SYS namespace:
/// <example>
/// set sc = ##class(SYS.Monitor.SAM.Config).AddApplicationClass("APP.monitor.InteroperabilityMetrics","APP")
/// </example>
Class APP.monitor.InteroperabilityMetrics Extends %SYS.Monitor.SAM.Abstract
{

/// Metric name prefix. Must not be "iris" (reserved for native metrics).
Parameter PRODUCT = "app";

/// Called by the /api/monitor/metrics endpoint on each scrape. Keep it fast.
Method GetSensors() As %Status
{
    set sc = $$$OK
    try {
        // Production running state: 1 when a production is active, else 0.
        set prod = ##class(Ens.Director).GetActiveProductionName()
        set running = (prod '= "")
        if prod = "" set prod = "none"
        do ..SetSensor("production_running", +running, prod)

        // Backup heartbeat: seconds since the last recorded successful backup.
        // The demo scripts maintain these globals; a missing value yields a large
        // sentinel so the staleness alert fires.
        do ..SetSensor("backup_age_seconds", ..AgeSeconds($get(^APP.Monitor("backup", "last"))))
        do ..SetSensor("journal_backup_age_seconds", ..AgeSeconds($get(^APP.Monitor("journalbackup", "last"))))
    }
    catch ex {
        set sc = ex.AsStatus()
    }
    quit sc
}

/// Seconds elapsed since pWhen, a UTC $ZTIMESTAMP value ("days,seconds").
/// Empty input returns ~10 years so staleness alerts fire on a fresh instance.
ClassMethod AgeSeconds(pWhen As %String = "") As %Integer
{
    if pWhen = "" quit 315360000
    set now = $ztimestamp
    set nowSec = ($piece(now, ",", 1) * 86400) + $piece(now, ",", 2)
    set whenSec = ($piece(pWhen, ",", 1) * 86400) + $piece(pWhen, ",", 2)
    set age = nowSec - whenSec
    quit $select(age < 0:0, 1:age)
}

}
