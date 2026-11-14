from pathlib import Path
import shutil,json
root=Path.cwd().resolve();mapping={}
def move(rel,dest):
 src=root/rel;dst=root/dest
 assert src.resolve().is_relative_to(root) and dst.resolve().is_relative_to(root)
 if not src.exists():return
 assert not dst.exists(),str(dst)
 dst.parent.mkdir(parents=True,exist_ok=True);shutil.move(str(src),str(dst));mapping[rel.replace('\\','/')]=dest.replace('\\','/')
for stem in ['arena','iso_visual']:
 for ext in ['.gd','.gd.uid','.tscn']:move(stem+ext,'game/'+stem+ext)
for stem in ['combat_check','pixel_check','iso_check']:
 for ext in ['.gd','.gd.uid','.tscn']:move(stem+ext,'tests/'+stem+ext)
for stem in ['fighter_visual','reaper_visual','pixel_visual','knight_visual','rogue_visual','knight_check','rogue_check','visual_check','model_preview']:
 for ext in ['.gd','.gd.uid','.tscn']:move(stem+ext,'archive/scripts/'+stem+ext)
for folder in ['grim_reaper','iron_knight','pixel_ninja','pixel_rogue']:move('assets/'+folder,'archive/assets/'+folder)
for p in list(root.glob('*.png')):
 move(p.name,'screenshots/'+p.name)
 move(p.name+'.import','screenshots/'+p.name+'.import')
for p in list(root.iterdir()):
 if p.suffix.lower() in ['.msi','.zip','.aseprite-extension'] or p.name=='VisualStudioSetup.exe':move(p.name,'tools/installers/'+p.name)
# Rewrite resource paths, including references inside historical scenes.
text_ext={'.gd','.tscn','.tres','.godot','.md','.txt','.import'}
for p in root.rglob('*'):
 if not p.is_file() or p.suffix not in text_ext or any(x in p.relative_to(root).parts for x in ['.godot','tools']):continue
 try:s=p.read_text(encoding='utf-8-sig')
 except UnicodeError:continue
 old=s
 for a,b in sorted(mapping.items(),key=lambda x:-len(x[0])):
  s=s.replace('res://'+a,'res://'+b)
  s=s.replace('res://'+a+'/', 'res://'+b+'/')
 if s!=old:p.write_text(s,encoding='utf-8')
(root/'archive/.gdignore').write_text('')
(root/'archive/MOVIMIENTOS.json').write_text(json.dumps(mapping,indent=2),encoding='utf-8')
