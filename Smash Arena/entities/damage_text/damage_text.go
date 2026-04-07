components {
  id: "damage_text"
  component: "/entities/damage_text/damage_text.script"
}
embedded_components {
  id: "label"
  type: "label"
  data: "size {\n"
  "  x: 128.0\n"
  "  y: 32.0\n"
  "}\n"
  "color {\n"
  "  x: 0.6\n"
  "  y: 0.0\n"
  "  z: 0.0\n"
  "}\n"
  "outline {\n"
  "  x: 0.8\n"
  "  y: 0.2\n"
  "  z: 0.2\n"
  "}\n"
  "text: \"-25\"\n"
  "font: \"/druid/fonts/druid_text_bold.font\"\n"
  "material: \"/builtins/fonts/label-df.material\"\n"
  ""
  scale {
    x: 0.5
    y: 0.5
  }
}
