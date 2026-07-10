components {
  id: "unit"
  component: "/entities/unit/unit.script"
}
embedded_components {
  id: "collisionobject"
  type: "collisionobject"
  data: "type: COLLISION_OBJECT_TYPE_DYNAMIC\n"
  "mass: 1.0\n"
  "friction: 0.0\n"
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
  "  data: 32.0\n"
  "}\n"
  "linear_damping: 0.8\n"
  "angular_damping: 1.0\n"
  "locked_rotation: true\n"
  ""
}
embedded_components {
  id: "hp_back"
  type: "sprite"
  data: "default_animation: \"hp_bar_back\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "slice9 {\n"
  "  x: 8.0\n"
  "  y: 8.0\n"
  "  z: 8.0\n"
  "  w: 8.0\n"
  "}\n"
  "size {\n"
  "  x: 64.0\n"
  "  y: 21.0\n"
  "}\n"
  "size_mode: SIZE_MODE_MANUAL\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/assets/atlas/gui.atlas\"\n"
  "}\n"
  ""
  position {
    x: -29.0
    y: 44.0
    z: 0.5
  }
  scale {
    y: 0.5
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
  data: "default_animation: \"blue_platform\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/assets/atlas/gui.atlas\"\n"
  "}\n"
  ""
  position {
    z: 0.3
  }
  scale {
    x: 0.5
    y: 0.5
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
    x: -30.0
    y: 44.0
    z: 0.6
  }
  scale {
    x: 7.5
    y: 1.05
  }
}
embedded_components {
  id: "sprite"
  type: "sprite"
  data: "default_animation: \"monk\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/assets/atlas/units.atlas\"\n"
  "}\n"
  ""
  position {
    z: 0.25
  }
  scale {
    x: 0.2
    y: 0.2
  }
}
embedded_components {
  id: "outline"
  type: "sprite"
  data: "default_animation: \"path59\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/assets/atlas/gui.atlas\"\n"
  "}\n"
  ""
  position {
    z: 0.18
  }
  scale {
    x: 0.6
    y: 0.6
  }
}
embedded_components {
  id: "effect"
  type: "sprite"
  data: "default_animation: \"ui_circle_64\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/druid/druid.atlas\"\n"
  "}\n"
  ""
}
embedded_components {
  id: "effect_one_shot_factory"
  type: "factory"
  data: "prototype: \"/entities/particle/one_shot.go\"\n"
  ""
}
embedded_components {
  id: "effect_constant_factory"
  type: "factory"
  data: "prototype: \"/entities/particle/constant.go\"\n"
  ""
}
embedded_components {
  id: "effect_trail_factory"
  type: "factory"
  data: "prototype: \"/entities/particle/trail.go\"\n"
  ""
}
