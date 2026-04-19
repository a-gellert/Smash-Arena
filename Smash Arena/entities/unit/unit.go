components {
  id: "unit"
  component: "/entities/unit/unit.script"
}
embedded_components {
  id: "collisionobject"
  type: "collisionobject"
  data: "type: COLLISION_OBJECT_TYPE_DYNAMIC\n"
  "mass: 1.0\n"
  "friction: 0.1\n"
  "restitution: 1.0\n"
  "group: \"unit\"\n"
  "mask: \"unit\"\n"
  "mask: \"wall\"\n"
  "embedded_collision_shape {\n"
  "  shapes {\n"
  "    shape_type: TYPE_SPHERE\n"
  "    position {\n"
  "    }\n"
  "    rotation {\n"
  "    }\n"
  "    index: 0\n"
  "    count: 1\n"
  "  }\n"
  "  data: 25.0\n"
  "}\n"
  "linear_damping: 0.7\n"
  "angular_damping: 1.0\n"
  "locked_rotation: true\n"
  ""
}
embedded_components {
  id: "hp_back"
  type: "sprite"
  data: "default_animation: \"pixel_copy\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/assets/atlas/gui.atlas\"\n"
  "}\n"
  ""
  position {
    x: -20.0
    y: 35.0
    z: 0.5
  }
  scale {
    x: 38.0
    y: 10.0
  }
}
embedded_components {
  id: "damage_factory"
  type: "factory"
  data: "prototype: \"/entities/damage_text/damage_text.go\"\n"
  ""
}
embedded_components {
  id: "platform"
  type: "sprite"
  data: "default_animation: \"ui_circle_32\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/druid/druid.atlas\"\n"
  "}\n"
  ""
  position {
    z: 0.1
  }
  scale {
    x: 1.5
    y: 1.5
  }
}
embedded_components {
  id: "hp_fill"
  type: "sprite"
  data: "default_animation: \"hp_bar\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "size {\n"
  "  x: 4.0\n"
  "  y: 4.0\n"
  "}\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/assets/atlas/gui.atlas\"\n"
  "}\n"
  ""
  position {
    x: -19.0
    y: 35.0
    z: 0.6
  }
  scale {
    x: 4.5
  }
}
embedded_components {
  id: "sprite"
  type: "sprite"
  data: "default_animation: \"ui_circle_32\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/druid/druid.atlas\"\n"
  "}\n"
  ""
  position {
    z: 0.2
  }
}
embedded_components {
  id: "name"
  type: "label"
  data: "size {\n"
  "  x: 128.0\n"
  "  y: 32.0\n"
  "}\n"
  "color {\n"
  "  x: 0.0\n"
  "  y: 0.0\n"
  "  z: 0.0\n"
  "}\n"
  "outline {\n"
  "  x: 0.5019608\n"
  "  y: 0.5019608\n"
  "  z: 0.5019608\n"
  "}\n"
  "text: \"Label\"\n"
  "font: \"/druid/fonts/druid_text_bold.font\"\n"
  "material: \"/builtins/fonts/label-df.material\"\n"
  ""
  position {
    z: 0.7
  }
  scale {
    x: 0.3
    y: 0.3
  }
}
embedded_components {
  id: "outline"
  type: "sprite"
  data: "default_animation: \"ui_circle_64\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/druid/druid.atlas\"\n"
  "}\n"
  ""
  scale {
    x: 0.9
    y: 0.9
  }
}
