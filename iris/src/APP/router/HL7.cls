/// 
Class APP.router.HL7 Extends Ens.Rule.Definition
{

Parameter RuleAssistClass = "EnsLib.HL7.MsgRouter.RuleAssist";

XData RuleDefinition [ XMLNamespace = "http://www.intersystems.com/rule" ]
{
<ruleDefinition alias="" context="EnsLib.HL7.MsgRouter.RoutingEngine" production="APPPKG.FoundationProduction">
<ruleSet name="" effectiveBegin="" effectiveEnd="">
<rule name="ORU to EMR">
<constraint name="source" value=""></constraint>
<constraint name="docCategory" value="2.3"></constraint>
<constraint name="docName" value="ORU_R01"></constraint>
<when condition="1" comment="">
<foreach propertypath="HL7.{PIDgrpgrp().ORCgrp().OBXgrp().OBX}">
<when condition="(Segment.{ObservationIdentifier.identifier}=&quot;PDFREPORT&quot;)&amp;&amp;(Segment.{ValueType}=&quot;ED&quot;)" comment="">
<send transform="APP.transfo.ORU.transcodage" target="to EMR - FILE"></send>
<trace value="&quot;Encapsulted Data&quot;"></trace>
</when>
<when condition="(Segment.{ObservationIdentifier.identifier}=&quot;PDFREPORT&quot;)&amp;&amp;(Segment.{ValueType}=&quot;RP&quot;)" comment="">
<send transform="APP.transfo.ORU.transcodage" target="to EMR - FILE"></send>
<trace value="&quot;Reference Pointer&quot;"></trace>
</when>
<otherwise>
<trace value="&quot;no action&quot;"></trace>
</otherwise>
</foreach>
</when>
</rule>
<rule name="ORU to FILE">
<constraint name="source" value=""></constraint>
<constraint name="docCategory" value="2.3"></constraint>
<constraint name="docName" value="ORU_R01"></constraint>
<when condition="((Source Contains &quot;FILE&quot;)=0)&amp;&amp;(HL7.{MSH:ReceivingFacility.namespaceID}=&quot;FILE&quot;)" comment="">
<send transform="APP.transfo.ORU.transcodage" target="forward to LAB RESULT from APP - FILE"></send>
<trace value="&quot;Forward to LAB RESULT from APP - FILE&quot;"></trace>
</when>
</rule>
<rule name="ADT to APP">
<constraint name="source" value=""></constraint>
<constraint name="docCategory" value=""></constraint>
<constraint name="docName" value=""></constraint>
<when condition="(Source Contains &quot;IHE PAM&quot;)&amp;&amp;(HL7.{MSH:9.1}=&quot;ADT&quot;)" comment="">
<send transform="APP.transfo.IHEPAM.seances" target="forward Patient Information to APP - MLLP"></send>
<trace value="&quot;Forward IHE PAM ADT to APP MLLP&quot;"></trace>
</when>
<when condition="((Source Contains &quot;FILE&quot;)=0)&amp;&amp;(HL7.{MSH:9.1}=&quot;ADT&quot;)" comment="">
<send transform="" target="forward Patient Information to APP - FILE,forward Patient Information to APP - HTTP,forward Patient Information to APP - MLLP"></send>
<trace value="&quot;Forward ADT to APP FILE/HTTP/MLLP&quot;"></trace>
</when>
</rule>
</ruleSet>
</ruleDefinition>
}

}
