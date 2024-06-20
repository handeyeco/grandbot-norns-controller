-- Control Grandbot
--
-- by handeyeco
--
-- Guide
--
-- All screens:
-- - E1: change page
-- - E2: select parameter
-- - E3: change parameter
--
-- Help screen:
-- - K2: send panic message
-- - K3: randomize settings
--
-- Param screen:
-- - K2: slip sequence
-- - K3: generate sequence
--
-- MIDI screen:
-- - K2: reset params
-- - K3: send params

controls = {
  { name = "swing", cc = 115, id = "swing", default = 0 },
  { name = "slip chance", cc = 89, id = "slip-chance", default = 10 },

  { name = "base note length", cc = 20, id = "base-note-length", default = 0 },
  { name = "sequence length", cc = 21, id = "sequence-length", default = 0 },
  { name = "1 oct up chance", cc = 22, id = "one-octave-up-chance", default = 10 },
  { name = "1 oct down chance", cc = 23, id = "one-octave-down-chance", default = 10 },
  { name = "2 oct up chance", cc = 24, id = "two-octave-up-chance", default = 5 },
  { name = "2 oct down chance", cc = 25, id = "two-octave-down-chance", default = 5 },
  { name = "double length chance", cc = 26, id = "double-length-chance", default = 5 },
  { name = "half length chance", cc = 27, id = "half-length-chance", default = 10 },
  { name = "ratchet chance", cc = 28, id = "ratchet-chance", default = 0 },
  { name = "rest chance", cc = 29, id = "rest-chance", default = 5 },
  { name = "run chance", cc = 30, id = "run-chance", default = 0 },

  { name = "fifth up chance", cc = 85, id = "fifth-up-chance", default = 0 },
  { name = "random interval chance", cc = 86, id = "random-interval-chance", default = 0 },
  { name = "random length chance", cc = 87, id = "random-length-chance", default = 0 },

  { name = "sort notes", cc = 114, id = "sort-notes", default = 0 },

  { name = "midi ch in", cc = 14, id = "midi-ch-in", default = 0 },
  { name = "midi ch out", cc = 15, id = "midi-ch-out", default = 0 },
  { name = "use speaker", cc = 119, id = "use-speaker", default = 0 },
}

page = 1

active_control_index = 1

confirming_reset_values = false
confirming_send_values = false

confirming_random_patch = false
confirming_panic = false

confirming_generate = false
confirming_slip = false

active_midi_index = 1

in_midi_index = 1
in_midi_channel = 1
in_midi = midi.connect(in_midi_index)

out_midi_index = 1
out_midi_channel = 1
out_midi = midi.connect(out_midi_index)

function setupMidiCallback()
  in_midi.event = function(data)
    local message = midi.to_msg(data)
    if (message.type == "clock") then
      out_midi:clock()
    elseif (message.type == "start") then
      out_midi:start()
    elseif (message.type == "stop") then
      out_midi:stop()
    elseif (message.type == "continue") then
      out_midi:continue()
    elseif (message.ch == in_midi_channel) then
      message.ch = out_midi_channel
      out_midi:send(midi.to_data(message))
    end
  end
end

function init()
  for _, control in pairs(controls) do
    params:add{
      type="number",
      id=control.id,
      min=0,
      max=127,
      default=control.default,
      action=function(x) out_midi:cc(control.cc, x) end
    }
  end
  setupMidiCallback()
end

function drawLine(yPos, leftText, rightText, active)
  local textPos = yPos + 7
  if active then
    screen.level(15)
    screen.rect(0,yPos,256,9)
    screen.fill()
    screen.level(0)
  else
    screen.level(2)
  end

  screen.move(1, textPos)
  screen.text(leftText)
  screen.move(128-1, textPos)
  screen.text_right(rightText)
end

function drawMenu()
  for i=1, #controls do
    local control = controls[i]
    local yPos = 0
    if active_control_index < 4 then
      yPos = (i - 1) * 10
    else
      yPos = ((i - active_control_index + 3) * 10)
    end
    drawLine(
      yPos,
      control.name,
      params:get(control.id),
      active_control_index == i
    )
  end
end

function drawHelp()
  drawLine(0, "this page", "", false)
  drawLine(10, "", "k2:panic k3:random", false)
  drawLine(20, "param page", "", false)
  drawLine(30, "", "k2:slip k3:generate", false)
  drawLine(40, "midi page", "", false)
  drawLine(50, "", "k2:reset k3:send", false)
end

function drawMidiOptions()
  drawLine(0, "in:", in_midi_index .. " " .. midi.devices[in_midi_index].name, active_midi_index==1)
  drawLine(10, "in ch:", in_midi_channel, active_midi_index==2)
  drawLine(20, "out:", out_midi_index .. " " .. midi.devices[out_midi_index].name, active_midi_index==3)
  drawLine(30, "out ch:", out_midi_channel, active_midi_index==4)
end

function confirm(text)
  screen.level(15)
  screen.move(128/2, 64/2)
  screen.text_center(text)
  screen.move(128/2, 64/2 + 10)
  screen.level(1)
  screen.text_center("k2=back, k3=confirm")
end

function redraw()
  screen.clear()
  screen.fill()
  if confirming_send_values then
    confirm("send all values?")
  elseif confirming_panic then
    confirm("send panic message?")
  elseif confirming_random_patch then
    confirm("create random patch?")
  elseif confirming_reset_values then
    confirm("reset all values?")
  elseif confirming_generate then
    confirm("generate new sequence?")
  elseif confirming_slip then
    confirm("slip existing sequence?")
  elseif page == 0 then
    drawHelp()
  elseif page == 1 then
    drawMenu()
  elseif page == 2 then
    drawMidiOptions()
  end
  screen.update()
end

function handleMenuEncoder(n,d)
  if n == 2 then
    active_control_index = util.clamp(active_control_index + d, 1, #controls)
  elseif n == 3 then
    params:delta(controls[active_control_index].id, d)
  end
end

function handleMidiEncoder(n,d)
  if n == 2 then
    active_midi_index = util.clamp(active_midi_index + d, 1, 4)
  elseif n == 3 then
    if (active_midi_index == 1) then
      in_midi_index = util.clamp(in_midi_index + d, 1, #midi.devices)
      in_midi = midi.connect(in_midi_index)
      setupMidiCallback()
    elseif (active_midi_index == 2) then
      in_midi_channel = util.clamp(in_midi_channel + d, 1, 16)
    elseif (active_midi_index == 3) then
      out_midi_index = util.clamp(out_midi_index + d, 1, #midi.devices)
      out_midi = midi.connect(out_midi_index)
    elseif (active_midi_index == 4) then
      out_midi_channel = util.clamp(out_midi_channel + d, 1, 16)
    end
  end
end

function enc(n,d)
  if (n == 1) then
    resetConfirm()
    page = util.clamp(page + d, 0, 2)
  elseif (page == 1) then
    handleMenuEncoder(n,d)
  elseif (page == 2) then
    handleMidiEncoder(n,d)
  end
  redraw()
end

function sendValues()
  params:bang()
end

function randomPatch()
  for _, control in pairs(controls) do
    if control.cc > 15 and control.cc < 114 then
      params:set(control.id, math.random(1, 127))
    end
  end
end

function resetParams()
  for _, control in pairs(controls) do
    if control.cc > 15 and control.cc < 114 then
      params:set(control.id, control.default)
    end
  end
end

function resetConfirm()
  confirming_panic = false
  confirming_random_patch = false

  confirming_reset_values = false
  confirming_send_values = false

  confirming_generate = false
  confirming_slip = false
end

function sendCommand(cc)
  out_midi:cc(cc, 0)
  out_midi:cc(cc, 127)
  out_midi:cc(cc, 0)
end

function handleHelpKey(n,z)
  if z == 1 then
    if n == 2 then
      if confirming_panic or confirming_random_patch then
        resetConfirm()
      else
        confirming_panic = true
      end
    elseif n == 3 then
      if confirming_panic then
        resetConfirm()
        sendCommand(117)
      elseif confirming_random_patch then
        resetConfirm()
        randomPatch()
      else
        confirming_random_patch = true
      end
    end
  end
end

function handleMenuKey(n,z)
  if z == 1 then
    if n == 2 then
      if confirming_generate or confirming_slip then
        resetConfirm()
      else
        confirming_slip = true
      end
    elseif n == 3 then
      if confirming_generate then
        resetConfirm()
        sendCommand(118)
      elseif confirming_slip then
        resetConfirm()
        sendCommand(116)
      else
        confirming_generate = true
      end
    end
  end
end

function handleMidiKey(n,z)
  if z == 1 then
    if n == 2 then
      if confirming_reset_values or confirming_send_values then
        resetConfirm()
      else
        confirming_reset_values = true
      end
    elseif n == 3 then
      if confirming_reset_values then
        resetConfirm()
        resetParams()
      elseif confirming_send_values then
        resetConfirm()
        sendValues()
      else
        confirming_send_values = true
      end
    end
  end
end

function key(n,z)
  if (page == 0) then
    handleHelpKey(n,z)
  elseif (page == 1) then
    handleMenuKey(n,z)
  elseif (page == 2) then
    handleMidiKey(n,z)
  end
  redraw()
end