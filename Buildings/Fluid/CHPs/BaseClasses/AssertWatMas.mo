within Buildings.Fluid.CHPs.BaseClasses;
model AssertWatMas "Assert if water mass flow is outside boundaries"
  extends Modelica.Blocks.Icons.Block;
  replaceable parameter Buildings.Fluid.CHPs.Data.Generic per
    "Performance data"
    annotation (Placement(transformation(extent={{-98,-98},{-78,-78}})));

  Modelica.Blocks.Interfaces.BooleanInput runSig
    "Flag is true when electricity/heat demand larger than zero" annotation (
      Placement(transformation(extent={{-140,20},{-100,60}}),
        iconTransformation(extent={{-140,20},{-100,60}})));
  Modelica.Blocks.Interfaces.RealInput mWat_flow(unit="kg/s") "Water flow rate"
    annotation (Placement(transformation(extent={{-140,-60},{-100,-20}}),
        iconTransformation(extent={{-140,-60},{-100,-20}})));

  Modelica.Blocks.Logical.Nand nand
    annotation (Placement(transformation(extent={{-10,-10},{10,10}})));
  Buildings.Controls.OBC.CDL.Utilities.Assert assMes(message="Water flow rate is lower than the minimum!")
    "Assert function for checking water flow rate"
    annotation (Placement(transformation(extent={{80,-10},{100,10}})));

protected
  Modelica.Blocks.Logical.LessThreshold lessThreshold(threshold=per.mWatMin)
    annotation (Placement(transformation(extent={{-60,-50},{-40,-30}})));

equation

  connect(lessThreshold.u, mWat_flow)
    annotation (Line(points={{-62,-40},{-120,-40}}, color={0,0,127}));
  connect(nand.u1, runSig) annotation (Line(points={{-12,0},{-20,0},{-20,40},{-120,
          40}}, color={255,0,255}));
  connect(nand.u2, lessThreshold.y) annotation (Line(points={{-12,-8},{-20,-8},{-20,
          -40},{-39,-40}}, color={255,0,255}));
  connect(nand.y, assMes.u)
    annotation (Line(points={{11,0},{78,0}}, color={255,0,255}));
  annotation (
    defaultComponentName="assWatMas",
    Diagram(coordinateSystem(extent={{-100,-100},{100,100}})),
    Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={
        Rectangle(
          extent={{-100,-100},{100,100}},
          lineColor={0,0,127},
          fillColor={255,255,255},
          fillPattern=FillPattern.Solid),
        Polygon(
          points={{0,80},{-80,-60},{80,-60},{0,80}},
          fillColor={0,0,0},
          fillPattern=FillPattern.Solid,
          pattern=LinePattern.None,
          lineColor={0,0,0}),
        Polygon(
          points={{0,72},{-72,-56},{72,-56},{0,72}},
          lineColor={0,0,0},
          fillColor={255,255,170},
          fillPattern=FillPattern.Solid),
        Rectangle(
          extent={{-4,38},{2,-24}},
          fillColor={0,0,0},
          fillPattern=FillPattern.Solid,
          pattern=LinePattern.None),
        Ellipse(
          extent={{-6,-32},{4,-42}},
          pattern=LinePattern.None,
          fillColor={0,0,0},
          fillPattern=FillPattern.Solid)}),
    Documentation(info="<html>
<p>
The model sends a warning message if the water mass flow is lower than the minimum defined by the manufacturer.  
</p>
</html>", revisions="<html>
<ul>
<li>
June 01, 2019 by Tea Zakula:<br/>
First implementation.
</li>
</ul>
</html>"));
end AssertWatMas;
