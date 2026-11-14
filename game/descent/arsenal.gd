extends RefCounted
const GROUPS=["Q · Corte","F · Filo","V · Parry"]
const OPTIONS=[
 ["Alcance: +3 m, −15 % daño","Fulgor: +15 % daño, −2 m"],
 ["Ascenso: +3 impulso vertical","Barrido: +3 m/s empuje lateral"],
 ["Disciplina: +8 energía al acertar","Respiro: +8 vida al acertar"]
]
static func valid(value:Array) -> bool:
 if value.size()!=3:return false
 for choice in value:
  if not choice is int or choice<0 or choice>1:return false
 return true
