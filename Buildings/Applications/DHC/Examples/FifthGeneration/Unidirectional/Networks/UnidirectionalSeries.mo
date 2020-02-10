within Buildings.Applications.DHC.Examples.FifthGeneration.Unidirectional.Networks;
model UnidirectionalSeries
  "Hydraulic network for unidirectional series DHC system"
  extends Buildings.Applications.DHC.Networks.BaseClasses.PartialDistribution;
  parameter Modelica.SIunits.MassFlowRate mDis_flow_nominal
    "Nominal mass flow rate in the distribution line";
  parameter Modelica.SIunits.MassFlowRate mCon_flow_nominal[nCon]
    "Nominal mass flow rate in each connection line";
  parameter Modelica.SIunits.Length lDis[nCon]
    "Length of the distribution pipe before each connection";
  parameter Modelica.SIunits.Length lCon[nCon]
    "Length of each connection pipe (supply only, not counting return line)";
  parameter Modelica.SIunits.Length lEnd = sum(lDis)
    "Length of the end of the distribution line (after last connection)";
  parameter Modelica.SIunits.Length dhDis
    "Hydraulic diameter of the distribution pipe";
  parameter Modelica.SIunits.Length dhCon[nCon]
    "Hydraulic diameter of each connection pipe";
  // COMPONENTS
  replaceable BaseClasses.ConnectionSeries con[nCon](
    redeclare each final package Medium = Medium,
    each mDis_flow_nominal=mDis_flow_nominal,
    mCon_flow_nominal=mCon_flow_nominal,
    lDis=lDis,
    lCon=lCon,
    each dhDis=dhDis,
    dhCon=dhCon,
    each final allowFlowReversal=allowFlowReversal)
    "Connection to agent"
    annotation (Placement(transformation(extent={{-10,-10},{10,10}})));
  replaceable BaseClasses.PipeDistribution pipEnd(
    redeclare final package Medium=Medium,
    m_flow_nominal=mDis_flow_nominal,
    dh=dhDis,
    length=lEnd,
    final allowFlowReversal=allowFlowReversal)
    "Pipe representing the end of the distribution line (after last connection)"
    annotation (Placement(transformation(extent={{40,-10},{60,10}})));
equation
  connect(con.port_bCon, ports_bCon)
    annotation (Line(points={{0,10},{0,40},{-80,
          40},{-80,100}}, color={0,127,255}));
  connect(ports_aCon, con.port_aCon)
    annotation (Line(points={{80,100},{80,40},
          {6,40},{6,10}}, color={0,127,255}));
  // Connecting outlets to inlets for all instances of connection component
  if nCon >= 2 then
    for i in 2:nCon loop
      connect(con[i - 1].port_bDis, con[i].port_aDis);
    end for;
  end if;
  connect(port_aDisSup, con[1].port_aDis)
    annotation (Line(points={{-100,0},{-10,0}}, color={0,127,255}));
  connect(con[nCon].port_bDis, pipEnd.port_a)
    annotation (Line(points={{10,0},{40,0}}, color={0,127,255}));
  connect(pipEnd.port_b, port_bDisSup)
    annotation (Line(points={{60,0},{100,0}}, color={0,127,255}));
  annotation (
    defaultComponentName="dis",
    Icon(coordinateSystem(preserveAspectRatio=false), graphics={
        Rectangle(
          extent={{-6,-200},{6,200}},
          lineColor={0,0,255},
          pattern=LinePattern.None,
          fillColor={0,0,0},
          fillPattern=FillPattern.Solid,
          origin={0,0},
          rotation=90),
        Rectangle(
          extent={{-53,4},{53,-4}},
          lineColor={0,0,255},
          pattern=LinePattern.None,
          fillColor={0,0,0},
          fillPattern=FillPattern.Solid,
          origin={-120,47},
          rotation=90),
        Rectangle(
          extent={{-53,4},{53,-4}},
          lineColor={0,0,255},
          pattern=LinePattern.None,
          fillColor={0,0,0},
          fillPattern=FillPattern.Solid,
          origin={120,47},
          rotation=90)}),
    Diagram( coordinateSystem(preserveAspectRatio=false)));
end UnidirectionalSeries;
