within Buildings.Controls.OBC.CDL.Utilities;
block OptimalStart
    "Block that outputs the optimal start time for an HVAC system"
  extends Modelica.Blocks.Icons.Block;
  parameter Real occupancy[:] = 3600*{8, 18}
    "Occupancy table, each entry switching occupancy on or off";
  parameter Modelica.SIunits.Time tOptMax = 10800
    "Maximum optimal start time";
  parameter Modelica.SIunits.Time tOptIni = 900
    "Initial optimal start time";
  parameter Integer n = 3 "Number of previous days for averaging the temperature slope";
  parameter Boolean heating_only = false
    "Set to true if the HVAC system is heating only"
    annotation(Dialog(enable=not cooling_only));
  parameter Boolean cooling_only = false
    "Set to true if the HVAC system is cooling only"
    annotation(Dialog(enable=not heating_only));
  parameter Modelica.SIunits.TemperatureDifference uLow = 0
    "Temperature change hysteresis low parameter, should be a non-negative number";
  parameter Modelica.SIunits.TemperatureDifference uHigh = 1
    "Temperature change hysteresis high parameter, should be greater than uLow";
  Interfaces.RealInput TSetZonHea(
    final quantity="ThermodynamicTemperature",
    final unit="K",
    displayUnit="degC",
    min=200) if not cooling_only
    "Zone heating setpoint temperature during occupancy"
    annotation (
      Placement(transformation(extent={{-360,60},{-320,100}}),
        iconTransformation(extent={{-140,60},{-100,100}})));
  Interfaces.RealInput TZon(
    final quantity="ThermodynamicTemperature",
    final unit="K",
    displayUnit="degC",
    min=200) "Zone temperature" annotation (Placement(transformation(extent={{-358,
            -20},{-318,20}}),      iconTransformation(extent={{-140,-20},{-100,
            20}})));
  Interfaces.RealInput TSetZonCoo(
    final quantity="ThermodynamicTemperature",
    final unit="K",
    displayUnit="degC",
    min=200) if not heating_only
    "Zone cooling setpoint temperature during occupancy" annotation (
      Placement(transformation(extent={{-360,-100},{-320,-60}}),
        iconTransformation(extent={{-140,-100},{-100,-60}})));
  Interfaces.RealOutput tOpt(
    final quantity="Time",
    final unit="s",
    displayUnit="h") "Optimal start time of HVAC system"
    annotation (Placement(transformation(extent={{320,-10},{340,10}}),
                    iconTransformation(extent={{100,-10},{120,10}})));
  Interfaces.BooleanOutput Startup "The duration of optimal startup"
    annotation (Placement(transformation(extent={{320,-130},{340,-110}}),
        iconTransformation(extent={{100,-50},{120,-30}})));
  Continuous.Add add(k1=+1, k2=-1) if not cooling_only
    annotation (Placement(transformation(extent={{-300,60},{-280,80}})));
  Continuous.Add add1(k1=+1, k2=-1) if not heating_only
    annotation (Placement(transformation(extent={{-300,20},{-280,40}})));
  Continuous.Sources.ModelTime modTim
    annotation (Placement(transformation(extent={{-300,-70},{-280,-50}})));
  Continuous.Modulo mod
    annotation (Placement(transformation(extent={{-260,-90},{-240,-70}})));
  Continuous.Sources.Constant period(k=86400)
    "Period of optimal start calculation algorithm"
    annotation (Placement(transformation(extent={{-300,-110},{-280,-90}})));
  Continuous.Sources.Constant staCal(k=occupancy[1] - tOptMax)
    "Start calculation"
    annotation (Placement(transformation(extent={{-260,-130},{-240,-110}})));
  Continuous.GreaterEqual greEqu
    annotation (Placement(transformation(extent={{-208,-100},{-188,-80}})));
  Continuous.Hysteresis hys(uLow=uLow, uHigh=uHigh)
    "Comparing zone temperature with zone setpoint"
    annotation (Placement(transformation(extent={{-220,70},{-200,90}})));
  Logical.Latch lat
    "Stop calculation when the zone temperature reaches setpoint"
    annotation (Placement(transformation(extent={{-160,70},{-140,90}})));
  Logical.Timer tim(reset=true)
    "Record how much time the zone temperature reaches the setpoint"
    annotation (Placement(transformation(extent={{-52,80},{-32,100}})));

  Discrete.TriggeredSampler triSam(y_start=tOptIni)
    "Record how much time it takes to reach the setpoint with the maximum time cutoff"
    annotation (Placement(transformation(extent={{-20,80},{0,100}})));
  Logical.FallingEdge falEdg
    "Get the timing when the zone temperature reaches setpoint"
    annotation (Placement(transformation(extent={{-70,50},{-50,70}})));
  Logical.TrueHoldWithReset truHol(duration(displayUnit="h") = occupancy[2] -
      occupancy[1])
    annotation (Placement(transformation(extent={{-86,80},{-66,100}})));
  Continuous.LessEqual lesEqu
    annotation (Placement(transformation(extent={{-200,-10},{-180,10}})));
  Continuous.Sources.Constant stoCal(k=occupancy[1]) "Stop calculation"
    annotation (Placement(transformation(extent={{-260,0},{-240,20}})));
  Logical.Latch latMax "Stop calculation when it reaches the max start time"
    annotation (Placement(transformation(extent={{-126,80},{-106,100}})));
  Discrete.TriggeredSampler triSam1
    annotation (Placement(transformation(extent={{240,-60},{260,-40}})));
  Continuous.Sources.Constant maxStaTim(k=tOptMax)
    annotation (Placement(transformation(extent={{240,-4},{260,16}})));
  Continuous.Min min
    annotation (Placement(transformation(extent={{292,-10},{312,10}})));
  Discrete.MovingMean movMea(n=n, samplePeriod=86400)
    annotation (Placement(transformation(extent={{160,80},{180,100}})));
  Logical.Not not1
    annotation (Placement(transformation(extent={{-192,70},{-172,90}})));
  Continuous.Division temSlo "Calculate temperature slope "
    annotation (Placement(transformation(extent={{100,80},{120,100}})));
  Continuous.Division tOptCal
    "Calculate optimal start time based on the averaged previous temperature slope"
    annotation (Placement(transformation(extent={{280,80},{300,100}})));
  Discrete.TriggeredSampler triSam2(y_start=temSloDef)
    annotation (Placement(transformation(extent={{130,80},{150,100}})));
  Continuous.Sources.Constant dT(k=-0.1) if
                                         cooling_only
    "Reset negative temperature difference to zero"
    annotation (Placement(transformation(extent={{-300,100},{-280,120}})));
  Continuous.Max max
    annotation (Placement(transformation(extent={{-260,40},{-240,60}})));
  Continuous.Sources.Constant dT1(k=-0.1) if
                                          heating_only
    "Reset negative temperature difference to zero"
    annotation (Placement(transformation(extent={{-300,-20},{-280,0}})));
  Continuous.Sources.Constant dT2(k=0)
    "Reset negative temperature difference to zero"
    annotation (Placement(transformation(extent={{-260,110},{-240,130}})));
  Continuous.Max max1
    annotation (Placement(transformation(extent={{-200,100},{-180,120}})));
  Continuous.LessEqual lesEqu1
    annotation (Placement(transformation(extent={{20,80},{40,100}})));
  Continuous.Sources.Constant zeroOpt(k=0)
    "Avoid zero division cases when the optimal start time is 0"
    annotation (Placement(transformation(extent={{-40,30},{-20,50}})));
  Logical.Switch swi
    annotation (Placement(transformation(extent={{60,80},{80,100}})));
  Continuous.Sources.Constant defOptTim(k=tOptIni)
    "Default optimal start time in case of zero division"
    annotation (Placement(transformation(extent={{20,30},{40,50}})));
  Continuous.LessEqual lesEqu2
    annotation (Placement(transformation(extent={{200,80},{220,100}})));
  Continuous.Sources.Constant zeroTemSlo(k=0)
    "Avoid zero divison when the temperature slope is 0"
    annotation (Placement(transformation(extent={{152,30},{172,50}})));
  Logical.Switch swi1
    annotation (Placement(transformation(extent={{240,80},{260,100}})));
  Continuous.Sources.Constant defTemSlo(k=temSloDef)
    "Default temperature slope in case of zero division"
    annotation (Placement(transformation(extent={{192,30},{212,50}})));
protected
    parameter Modelica.SIunits.TemperatureSlope temSloDef = 1/3600
    "Default temperature slope in case of zero division";
equation
  connect(mod.y, greEqu.u1) annotation (Line(points={{-238,-80},{-220,-80},{-220,
          -90},{-210,-90}},
                         color={0,0,127}));
  connect(staCal.y, greEqu.u2) annotation (Line(points={{-238,-120},{-220,-120},
          {-220,-98},{-210,-98}}, color={0,0,127}));
  connect(period.y, mod.u2) annotation (Line(points={{-278,-100},{-274,-100},{-274,
          -86},{-262,-86}},
                      color={0,0,127}));
  connect(modTim.y, mod.u1) annotation (Line(points={{-278,-60},{-274,-60},{-274,
          -74},{-262,-74}}, color={0,0,127}));
  connect(tim.y, triSam.u)
    annotation (Line(points={{-30,90},{-22,90}},
                                              color={0,0,127}));
  connect(falEdg.y, triSam.trigger)
    annotation (Line(points={{-48,60},{-10,60},{-10,78.2}},color={255,0,255}));
  connect(tim.u, truHol.y)
    annotation (Line(points={{-54,90},{-64,90}}, color={255,0,255}));
  connect(lat.y,latMax. u) annotation (Line(points={{-138,80},{-138,90},{-128,90}},
                      color={255,0,255}));
  connect(latMax.y, truHol.u)
    annotation (Line(points={{-104,90},{-88,90}},  color={255,0,255}));
  connect(latMax.y, falEdg.u) annotation (Line(points={{-104,90},{-100,90},{-100,
          60},{-72,60}},   color={255,0,255}));
  connect(greEqu.y, triSam1.trigger) annotation (Line(points={{-186,-90},{250,-90},
          {250,-61.8}},                             color={255,0,255}));
  connect(maxStaTim.y, min.u1) annotation (Line(points={{262,6},{290,6}},
                               color={0,0,127}));
  connect(min.y, tOpt) annotation (Line(points={{314,0},{330,0}},
                   color={0,0,127}));
  connect(hys.y, not1.u)
    annotation (Line(points={{-198,80},{-194,80}},   color={255,0,255}));
  connect(not1.y, lat.clr) annotation (Line(points={{-170,80},{-164,80},{-164,74},
          {-162,74}}, color={255,0,255}));
  connect(latMax.y, Startup) annotation (Line(points={{-104,90},{-100,90},{-100,
          -120},{330,-120}},
                       color={255,0,255}));
  connect(tOptCal.y, triSam1.u) annotation (Line(points={{302,90},{310,90},{310,
          28},{226,28},{226,-50},{238,-50}},
                                         color={0,0,127}));
  connect(temSlo.y,triSam2. u)
    annotation (Line(points={{122,90},{128,90}},
                                               color={0,0,127}));
  connect(mod.y, lesEqu.u2) annotation (Line(points={{-238,-80},{-220,-80},{-220,
          -8},{-202,-8}},   color={0,0,127}));
  connect(triSam2.y, movMea.u)
    annotation (Line(points={{152,90},{158,90}}, color={0,0,127}));
  connect(triSam2.trigger, triSam1.trigger) annotation (Line(points={{140,78.2},
          {140,-90},{250,-90},{250,-61.8}}, color={255,0,255}));
  connect(tOptCal.u1, temSlo.u1) annotation (Line(points={{278,96},{268,96},{268,
          130},{90,130},{90,96},{98,96}},        color={0,0,127}));
  connect(triSam1.y, min.u2) annotation (Line(points={{262,-50},{280,-50},{280,-6},
          {290,-6}},     color={0,0,127}));
  connect(add1.y, max.u2) annotation (Line(points={{-278,30},{-272,30},{-272,44},
          {-262,44}}, color={0,0,127}));
  connect(add.y, max.u1) annotation (Line(points={{-278,70},{-272,70},{-272,56},
          {-262,56}}, color={0,0,127}));
  connect(dT1.y, max.u2) annotation (Line(points={{-278,-10},{-272,-10},{-272,44},
          {-262,44}}, color={0,0,127}));
  connect(max.y, hys.u) annotation (Line(points={{-238,50},{-230,50},{-230,80},{
          -222,80}}, color={0,0,127}));
  connect(dT.y, max.u1) annotation (Line(points={{-278,110},{-272,110},{-272,56},
          {-262,56}}, color={0,0,127}));
  connect(max.y, max1.u2) annotation (Line(points={{-238,50},{-230,50},{-230,104},
          {-202,104}}, color={0,0,127}));
  connect(max1.y, temSlo.u1) annotation (Line(points={{-178,110},{-150,110},{-150,
          130},{90,130},{90,96},{98,96}}, color={0,0,127}));
  connect(lesEqu.y, latMax.clr) annotation (Line(points={{-178,0},{-134,0},{-134,
          84},{-128,84}}, color={255,0,255}));
  connect(stoCal.y, lesEqu.u1) annotation (Line(points={{-238,10},{-220,10},{-220,
          0},{-202,0}}, color={0,0,127}));
  connect(triSam.y, lesEqu1.u1)
    annotation (Line(points={{2,90},{18,90}},  color={0,0,127}));
  connect(TSetZonCoo, add1.u2) annotation (Line(points={{-340,-80},{-310,-80},{-310,
          24},{-302,24}}, color={0,0,127}));
  connect(TZon, add1.u1) annotation (Line(points={{-338,0},{-314,0},{-314,36},{-302,
          36}}, color={0,0,127}));
  connect(TZon, add.u2) annotation (Line(points={{-338,0},{-314,0},{-314,64},{-302,
          64}}, color={0,0,127}));
  connect(TSetZonHea, add.u1) annotation (Line(points={{-340,80},{-310,80},{-310,
          76},{-302,76}}, color={0,0,127}));
  connect(movMea.y, lesEqu2.u1)
    annotation (Line(points={{182,90},{198,90}}, color={0,0,127}));
  connect(swi1.y, tOptCal.u2) annotation (Line(points={{262,90},{270,90},{270,84},
          {278,84}}, color={0,0,127}));
  connect(lesEqu2.y, swi1.u2)
    annotation (Line(points={{222,90},{238,90}}, color={255,0,255}));
  connect(defOptTim.y, swi.u1) annotation (Line(points={{42,40},{52,40},{52,98},
          {58,98}}, color={0,0,127}));
  connect(defTemSlo.y, swi1.u1) annotation (Line(points={{214,40},{226,40},{226,
          98},{238,98}},                   color={0,0,127}));
  connect(movMea.y, swi1.u3) annotation (Line(points={{182,90},{190,90},{190,114},
          {234,114},{234,82},{238,82}}, color={0,0,127}));
  connect(dT2.y, max1.u1) annotation (Line(points={{-238,120},{-220,120},{-220,116},
          {-202,116}}, color={0,0,127}));
  connect(zeroOpt.y, lesEqu1.u2) annotation (Line(points={{-18,40},{10,40},{10,82},
          {18,82}}, color={0,0,127}));
  connect(greEqu.y, lat.u) annotation (Line(points={{-186,-90},{-166,-90},{-166,
          80},{-162,80}}, color={255,0,255}));
  connect(lesEqu1.y, swi.u2)
    annotation (Line(points={{42,90},{58,90}}, color={255,0,255}));
  connect(triSam.y, swi.u3) annotation (Line(points={{2,90},{10,90},{10,114},{46,
          114},{46,82},{58,82}},
                            color={0,0,127}));
  connect(zeroTemSlo.y, lesEqu2.u2) annotation (Line(points={{174,40},{186,40},{
          186,82},{198,82}}, color={0,0,127}));
  connect(swi.y, temSlo.u2) annotation (Line(points={{82,90},{88,90},{88,84},{98,
          84}}, color={0,0,127}));
  annotation (
defaultComponentName="optSta",
  Documentation(info="<html>
<p>
This block outputs the optimal start time each day for an HVAC system prior to the occupied time. 
The calculation is based on the concept of temperature slope, indicating the 
temperature change rate of a zone, with the unit <code>K/s</code>. The algorithm is described briefly 
in the steps blow.
</p>
<p>
<h4>Step 1: get sampled temperature difference <code>&Delta;T</code></h4>
Each day at a certain time before the occupancy, the algorithm takes a sample of the zone 
temperature. The sampling time is defined as occupancy start
time <code> - tOptMax</code>, where <code>tOptMax</code> denotes the maximum
optimal start time.
<p>
After getting the zone temperature at the sampling time, the difference <code>&Delta;T</code> between this zone 
temperature and the occupied zone setpoint is calculated.
</p>
</p>
<p>
<h4>Step 2: calculate temeperature slope <code>Ts</code></h4>
After the HVAC system is started, a timer is used to record how much time <code>&Delta;t</code> the zone temperature 
reaches the setpoint. When the time becomes greater than the maximum start time, the maximum start time is used.
The temperature slope is thus approximated using the equation: <code>Ts=&Delta;T/&Delta;t</code>. 
</p>
<p>
<h4>Step 3: calculate temperature slope moving average</h4>
After getting the temperature slope of each day, the moving average of the temperature slope <code>Ts_m</code> during the 
previous <code>n</code> days is calculated. 
</p>
<p>
<h4>Step 4: calculate optimal start time</h4>
The optimal start time is calculated using <code>&Delta;T</code> from Step 1 and the averaged temperature slope <code>Ts_m</code>
of the previous <code>n</code> days: <code>t_opt = &Delta;T/Ts_m</code>.
</p>
<p>
<h4>Initialization</h4>
During the initial day, the initial optimal start time parameter <code>tOptIni</code> is used.
</p>
<p>
<h4>Multiple zones</h4>
When there are multiple zones in the system, use the maximum zone temperature for cooling system and minimum zone temperature for 
heating system.
</p>
<h4>Validation</h4>
<p>
A validation can be found at
<a href=\"modelica://Buildings.Controls.OBC.CDL.Utilities.Validation.OptimalStart\">
Buildings.Controls.OBC.CDL.Utilities.Validation.OptimalStart</a>.
</p>
</html>",
revisions="<html>
<ul>
<li>
September 29, 2019, by Kun Zhang:<br/>
First implementation.
</li>
</ul>
</html>"),
Diagram(coordinateSystem(extent={{-320,-140},{320,140}})));
end OptimalStart;
