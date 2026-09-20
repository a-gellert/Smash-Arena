components {
  id: "script"
  component: "/entities/particle/explosion.script"
}
components {
  id: "explosion"
  component: "/entities/particle/explosion.particlefx"
  position {
    z: 0.2
  }
}
embedded_components {
  id: "shockwave"
  type: "sprite"
  data: "default_animation: \"ui_circle_64\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/druid/druid.atlas\"\n"
  "}\n"
  ""
  position {
    z: 0.1
  }
}
