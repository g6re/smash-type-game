-- Export the editable animation without regenerating or changing its frames.
local source=Sprite{fromFile="samurai/Idle/samurai-idle-8-directions.aseprite"}
local directions={"south","south-east","east","north-east","north","north-west","west","south-west"}
local sheet=Image(384,512,ColorMode.RGB)
for row,direction in ipairs(directions) do
  local tag=nil
  for _,candidate in ipairs(source.tags) do
    if candidate.name=="idle_"..direction then tag=candidate end
  end
  assert(tag and tag.fromFrame.frameNumber==(row-1)*6+1,"Expected directional tag: "..direction)
  -- Aseprite extends tags when inserting frames at their end; restore boundaries.
  tag.toFrame=source.frames[tag.fromFrame.frameNumber+5]
  for column=0,5 do
    local frame=tag.fromFrame.frameNumber+column
    for _,cel in ipairs(source.cels) do
      if cel.frame.frameNumber==frame then
        sheet:drawImage(cel.image,Point(column*64+cel.position.x,(row-1)*64+cel.position.y))
      end
    end
  end
end
sheet:saveAs("samurai/Idle/samurai-idle-sheet.png")
source:saveAs("samurai/Idle/samurai-idle-8-directions.aseprite")
