-- FIXME: upper range arc controls refactor (for other scripts)
-- FIXME: ui params labels and adaptive formaters (for other scripts)
-- FIXME: visual indicators for delaytime (rymd)
-- FIXME: visual indicators for pshift, fshift (skev)
-- FIXME: cutoff indicator and visuals (as with delaytime, pshift/fshift) when not on page 1
-- scriptname: bob
-- v1.2.0 @jah

engine.name = 'R'

SETTINGS_FILE = "bob.data"

R = require('r/lib/r') -- assumes r engine resides in ~/dust/code/r folder
ControlSpec = require('controlspec')
Formatters = require('formatters')
UI = include('lib/ui')
RoarFormatters = include('lib/formatters')
include('lib/common')
include('lib/common/settings')

function init()
  init_r()
  init_polls()
  init_params()
  init_ui()

  load_settings()
  load_params()

  cutoff_poll:start()

  start_ui()
end

function init_r()
  create_modules()
  set_static_module_params()
  connect_modules()

  engine.pollvisual(0, "FilterL.Frequency") -- TODO: should be indexed from 1
end

function create_modules()
  engine.new("LFO", "MultiLFO")
  engine.new("SoundIn", "SoundIn")
  engine.new("EnvF", "EnvF")
  engine.new("ModMix", "LinMixer")
  engine.new("FilterL", "LPLadder")
  engine.new("FilterR", "LPLadder")
  engine.new("SoundOut", "SoundOut")
end

function set_static_module_params()
  engine.set("FilterL.FM", 1)
  engine.set("FilterR.FM", 1)
  engine.set("ModMix.Out", 1)
end

function connect_modules()
  engine.connect("SoundIn/Left", "FilterL/In")
  engine.connect("SoundIn/Right", "FilterR/In")
  engine.connect("LFO/Sine", "ModMix/In1")
  engine.connect("SoundIn/Left", "EnvF/In")
  engine.connect("EnvF/Env", "ModMix/In2")
  engine.connect("ModMix/Out", "FilterL/FM")
  engine.connect("ModMix/Out", "FilterR/FM")
  engine.connect("FilterL/Out", "SoundOut/Left")
  engine.connect("FilterR/Out", "SoundOut/Right")
end

function init_polls()
  cutoff_poll = poll.set("poll1", function(value)
    local cutoff_page_param = page_params[1][1]
    local visual_values = cutoff_page_param.visual_values
    local visual_value = filter_spec:unmap(value)
    push_to_capped_list(visual_values, visual_value)
    UI.set_dirty()
  end)

  cutoff_poll.time = 1/FPS
end

function init_params()
  filter_spec = R.specs.LPLadder.Frequency:copy()
  filter_spec.default = 1000
  filter_spec.minval = 20
  filter_spec.maxval = 10000

  params:add {
    type="control",
    id="cutoff",
    name="Cutoff",
    controlspec=filter_spec,
    action=function (value)
      engine.set("FilterL.Frequency", value)
      engine.set("FilterR.Frequency", value)
      page_params[1][1].ind_ref = params:get_raw("cutoff")
      UI.set_dirty()
    end
  }

  resonance_spec = R.specs.LPLadder.Resonance:copy()
  resonance_spec.default = 0.5

  params:add {
    type="control",
    id="resonance",
    name="Resonance",
    controlspec=resonance_spec,
    formatter=Formatters.percentage,
    action=function (value)
      engine.set("FilterL.Resonance", value)
      engine.set("FilterR.Resonance", value)
      page_params[1][2].ind_ref = params:get("resonance")
      UI.set_dirty()
    end
  }

  local lfo_rate_spec = R.specs.MultiLFO.Frequency:copy()
  lfo_rate_spec.default = 0.5

  params:add {
    type="control",
    id="lfo_rate",
    name="LFO Rate",
    controlspec=lfo_rate_spec,
    formatter=Formatters.round(0.001),
    action=function (value)
      engine.set("LFO.Frequency", value)
      page_params[2][1].ind_ref = params:get_raw("lfo_rate")
      UI.set_dirty()
    end
  }

  local lfo_to_cutoff_spec = R.specs.LinMixer.In1
  lfo_to_cutoff_spec.default = 0.1

  params:add {
    type="control",
    id="lfo_to_cutoff",
    name="LFO > Cutoff",
    controlspec=lfo_to_cutoff_spec,
    formatter=Formatters.percentage,
    action=function (value)
      engine.set("ModMix.In1", value)
      page_params[2][2].ind_ref = params:get_raw("lfo_to_cutoff")
      UI.set_dirty()
    end
  }

  local env_attack_spec = R.specs.ADSREnv.Attack:copy()
  env_attack_spec.default = 50

  params:add {
    type="control",
    id="envf_attack",
    name="EnvF Attack",
    controlspec=env_attack_spec, -- TODO
    action=function (value)
      engine.set("EnvF.Attack", value)
      page_params[3][1].ind_ref = params:get_raw("envf_attack")
      UI.set_dirty()
    end
  }

  local env_decay_spec = R.specs.ADSREnv.Decay:copy()
  env_decay_spec.default = 100

  params:add {
    type="control",
    id="envf_decay",
    name="EnvF Decay",
    controlspec=env_decay_spec, -- TODO
    action=function (value)
      engine.set("EnvF.Decay", value)
      page_params[3][2].ind_ref = params:get_raw("envf_decay")
      UI.set_dirty()
    end
  }

  params:add {
    type="control",
    id="envf_sensitivity",
    name="EnvF Sensitivity",
    controlspec=ControlSpec.new(0, 1), -- TODO
    formatter=Formatters.percentage,
    action=function (value)
      engine.set("EnvF.Sensitivity", value)
      page_params[4][1].ind_ref = params:get_raw("envf_sensitivity")
      UI.set_dirty()
    end
  }

  local env_to_cutoff_spec = R.specs.LinMixer.In2
  env_to_cutoff_spec.default = 0.1

  params:add {
    type="control",
    id="env_to_cutoff",
    name="Env > Cutoff",
    controlspec=env_to_cutoff_spec,
    formatter=Formatters.percentage,
    action=function (value)
      engine.set("ModMix.In2", value)
      page_params[4][2].ind_ref = params:get_raw("env_to_cutoff")
      UI.set_dirty()
    end
  }
end

function init_ui()
  UI.init_arc {
    device = arc.connect(),
    on_delta = function(n, delta)
      arc_delta(n, delta)
    end,
    on_refresh = function(my_arc)
      local range = 44

      local function translate(n)
        n = util.round(n*range)
        return n
      end

      local function ring_map(n)
        if n < range/2 then
          n = 64-range/2+n
        else
          n = n-range/2
        end
        return n
      end

      local function ring_map_stroke(ring, start_n, end_n, level)
        for n=start_n, end_n do
          my_arc:led(ring, ring_map(n), level)
        end
      end

      local function draw_visual_values(ring, ui_param)
        local visual_values = ui_param.visual_values

        if visual_values then
          if #visual_values.content > 1 then
            local max_level = 2
            local prev_led_n = translate(visual_values.content[1])
            for idx=2, #visual_values.content do
              local led_n = translate(visual_values.content[idx])
              local min_n = math.min(prev_led_n, led_n)
              local max_n = math.max(prev_led_n, led_n)

              local level = util.round(max_level*1/5*idx) -- TODO: what is this calculation really?

              ring_map_stroke(ring, min_n, max_n, level)

              prev_led_n = led_n
            end
          end
        end
      end

      my_arc:all(0)
      for n=range/2, range/2+64-range do
        my_arc:led(1, n, 1)
        my_arc:led(2, n, 1)
      end

      local page_param_tuple = page_params[get_page()]

      draw_visual_values(1, page_param_tuple[1])
      draw_visual_values(2, page_param_tuple[2])

      local led1_n = ring_map(translate(params:get_raw(get_param_id_for_current_page(1))))
      local led2_n = ring_map(translate(params:get_raw(get_param_id_for_current_page(2))))

      my_arc:led(1, led1_n, 15)
      my_arc:led(2, led2_n, 15)

    end
  }

  UI.init_screen {
    on_refresh = function()
      redraw()
    end
  }

  page_params = {
    {
      {
        label="CUTOFF",
        id="cutoff",
        format=function(id)
          return RoarFormatters.adaptive_freq(params:get(id))
        end,
        visual_values = new_capped_list(math.floor(FPS/10))
      },
      {
        label="RES",
        id="resonance",
        format=function(id)
          return RoarFormatters.percentage(params:get(id))
        end
      }
    },
    {
      {
        label="LFO",
        id="lfo_rate",
        format=function(id)
          return RoarFormatters.adaptive_freq(params:get(id))
        end
      },
      {
        label="L>FRQ",
        id="lfo_to_cutoff",
        format=function(id)
          return RoarFormatters.percentage(params:get(id))
        end
      }
    },
    {
      {
        label="E.ATK",
        id="envf_attack",
        format=function(id)
          return RoarFormatters.adaptive_time(params:get(id))
        end
      },
      {
        label="E.DEC",
        id="envf_decay",
        format=function(id)
          return RoarFormatters.adaptive_time(params:get(id))
        end
      },
    },
    {
      {
        label="E.SNS",
        id="envf_sensitivity",
        format=function(id)
          return RoarFormatters.percentage(params:get(id))
        end
      },
      {
        label="E>FRQ",
        id="env_to_cutoff",
        format=function(id)
          return RoarFormatters.percentage(params:get(id))
        end
      }
    }
  }
end

function load_params()
  params:read()
  params:bang()
end

function cleanup()
  save_settings()
  params:write()
end
