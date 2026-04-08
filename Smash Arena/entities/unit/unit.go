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
  data: "default_animation: \"pixel\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/druid/druid.atlas\"\n"
  "}\n"
  ""
  position {
    x: -24.0
    y: 32.0
    z: 0.5
  }
  scale {
    x: 12.0
    y: 1.2
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
  scale {
    x: 1.5
    y: 1.5
  }
}
embedded_components {
  id: "hp_fill"
  type: "sprite"
  data: "default_animation: \"pixel\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "size {\n"
  "  x: 4.0\n"
  "  y: 4.0\n"
  "}\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/druid/druid.atlas\"\n"
  "}\n"
  ""
  position {
    x: -23.0
    y: 32.0
    z: 0.6
  }
  scale {
    x: 11.5
  }
}
