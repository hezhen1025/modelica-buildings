within Buildings.Applications.DHC.Loads.Examples;
model CouplingGeojsonRC_toUpdate
  "Example illustrating the coupling of a multizone RC model to a fluid loop"
  import Buildings;
  extends Modelica.Icons.Example;
  package Medium = Buildings.Media.Water "Fluid in the pipes";
  Buildings.BoundaryConditions.WeatherData.ReaderTMY3 weaDat(
    calTSky=Buildings.BoundaryConditions.Types.SkyTemperatureCalculation.HorizontalRadiation,
    computeWetBulbTemperature=false,
    filNam=Modelica.Utilities.Files.loadResource(
    "modelica://Buildings/Resources/weatherdata/USA_CA_San.Francisco.Intl.AP.724940_TMY3.mos"))
    "Weather data reader"
    annotation (Placement(transformation(extent={{110,-30},{90,-10}})));

  Buildings.Applications.DHC.Loads.Examples.BaseClasses.GeojsonRCBuilding bui
    annotation (Placement(transformation(extent={{40,-40},{60,-20}})));
  Buildings.Fluid.Sources.MassFlowSource_T supHea(
    use_m_flow_in=true,
    redeclare package Medium = Medium,
    use_T_in=true,
    nPorts=1)
    "Supply for heating water"
    annotation (Placement(
        transformation(
        extent={{-10,-10},{10,10}},
        rotation=0,
        origin={-32,30})));
  Buildings.Fluid.Sources.Boundary_pT   sinHea(
    redeclare package Medium = Medium,
    p=300000,
    T=couHea.T1_b_nominal,
    nPorts=1)
    "Sink for heating water"
    annotation (Placement(transformation(
        extent={{10,-10},{-10,10}},
        rotation=0,
        origin={100,30})));
  Buildings.Fluid.Sources.Boundary_pT sinCoo(
    redeclare package Medium = Medium,
    p=300000,
    T=couCoo.T1_b_nominal,
    nPorts=1)
    "Sink for chilled water"
    annotation (Placement(transformation(
        extent={{10,-10},{-10,10}},
        rotation=0,
        origin={100,-90})));
  Buildings.Fluid.Sources.MassFlowSource_T supCoo(
    use_m_flow_in=true,
    redeclare package Medium = Medium,
    use_T_in=true,
    nPorts=1)
   "Supply for chilled water"
   annotation (Placement(
        transformation(
        extent={{-10,-10},{10,10}},
        rotation=0,
        origin={-30,-90})));
  Modelica.Blocks.Sources.RealExpression THeaInlVal(y=couHea.T1_a_nominal)
    annotation (Placement(transformation(extent={{-100,14},{-80,34}})));
  Modelica.Blocks.Sources.RealExpression TCooInlVal(y=couCoo.T1_a_nominal)
    annotation (Placement(transformation(extent={{-100,-106},{-80,-86}})));
equation
  connect(weaDat.weaBus, bui.weaBus)
  annotation (Line(
      points={{90,-20},{50.1,-20}},
      color={255,204,51},
      thickness=0.5));
  connect(THeaInlVal.y, supHea.T_in) annotation (Line(points={{-79,24},{-66,24},{-66,34},{-44,34}}, color={0,0,127}));
  connect(TCooInlVal.y, supCoo.T_in)
    annotation (Line(points={{-79,-96},{-68,-96},{-68,-86},{-42,-86}}, color={0,0,127}));
  connect(supHea.ports[1], couHea.port_a) annotation (Line(points={{-22,30},{0,30}}, color={0,127,255}));
  connect(couHea.port_b, sinHea.ports[1]) annotation (Line(points={{20,30},{90,30}}, color={0,127,255}));
  connect(bui.yHea, couHea.yHeaCoo)
    annotation (Line(points={{61,-24},{80,-24},{80,0},{-10,0},{-10,22},{-2,22}}, color={0,0,127}));
  connect(bui.heaPorHea, couHea.heaPorLoa) annotation (Line(points={{40,-23},{20,-23},{20,25}}, color={191,0,0}));
  connect(supCoo.ports[1], couCoo.port_a) annotation (Line(points={{-20,-90},{0,-90}}, color={0,127,255}));
  connect(couCoo.port_b, sinCoo.ports[1]) annotation (Line(points={{20,-90},{90,-90}}, color={0,127,255}));
  connect(bui.yCoo, couCoo.yHeaCoo)
    annotation (Line(points={{61,-36},{80,-36},{80,-60},{-10,-60},{-10,-82},{-2,-82}}, color={0,0,127}));
  connect(bui.heaPorCoo, couCoo.heaPorLoa) annotation (Line(points={{40,-37},{20,-37},{20,-85}}, color={191,0,0}));
  connect(bui.m_flowHeaLoa, couHea.m_flow2)
    annotation (Line(points={{61,-27},{82,-27},{82,52},{-10,52},{-10,38},{-2,38}}, color={0,0,127}));
  connect(bui.m_flowCooLoa, couCoo.m_flow2)
    annotation (Line(points={{61,-33},{82,-33},{82,-114},{-10,-114},{-10,-98},{-2,-98}}, color={0,0,127}));
  connect(bui.fraLatCooReq, couCoo.fraLat)
    annotation (Line(points={{61,-31},{84,-31},{84,-118},{-12,-118},{-12,-94},{-2,-94}}, color={0,0,127}));
  connect(couCoo.m_flow1Req, supCoo.m_flow_in)
    annotation (Line(points={{22,-95},{26,-95},{26,-66},{-60,-66},{-60,-82},{-42,-82}}, color={0,0,127}));
  connect(couHea.m_flow1Req, supHea.m_flow_in)
    annotation (Line(points={{22,35},{32,35},{32,60},{-60,60},{-60,38},{-44,38}}, color={0,0,127}));
  annotation (
  Documentation(info="<html>
  <p>
  This example illustrates the use of
  <a href=\"modelica://Buildings.DistrictEnergySystem.Loads.BaseClasses.HeatingOrCooling\">
  Buildings.DistrictEnergySystem.Loads.BaseClasses.HeatingOrCooling</a>
  to transfer heat from a fluid stream to a simplified multizone RC model resulting
  from the translation of a GeoJSON model specified within Urbanopt UI, see
  <a href=\"modelica://Buildings.DistrictEnergySystem.Loads.Examples.BaseClasses.GeojsonExportBuilding\">
  Buildings.DistrictEnergySystem.Loads.Examples.BaseClasses.GeojsonExportBuilding</a>.
  </p>
  </html>"),
  Diagram(
        coordinateSystem(preserveAspectRatio=false, extent={{-100,-140},{140,80}})),
    __Dymola_Commands(file="Resources/Scripts/Dymola/Applications/DHC/Loads/Examples/CouplingGeojsonRC.mos"
        "Simulate and plot"));
end CouplingGeojsonRC_toUpdate;
