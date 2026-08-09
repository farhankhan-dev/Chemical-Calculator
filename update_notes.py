import json

user_data = """1	Ammonia	NH3	Gas at room temp; negative BP (-33.3°C) [citation:1][citation:12]	Students expect all compounds to be liquid/solid; must understand phase at STP	Yes - Add "Gas at STP" warning
2	Ethanol	C2H5OH	Common lab solvent; MP -114.1°C, BP 78.4°C [citation:2][citation:13]	Often confused with methanol (similar formula, very different toxicity)	Yes - Display toxicity warning
3	Methanol	CH3OH	Highly toxic; MP ~ -97.5°C, BP 64.5°C [citation:3][citation:14]	Can be fatal if ingested; similar odor and appearance to ethanol	Yes - Add "Highly Toxic - Fatal if Swallowed" warning
4	Acetone	C3H6O	Common solvent; low BP 56°C, MP -95°C [citation:4][citation:15]	Highly flammable; students may not expect such low BP	Yes - Add "Highly Flammable" warning
5	Benzene	C6H6	Carcinogenic; MP 5.5°C, BP 80°C [citation:5]	Cancer risk; student confusion with non-carcinogenic solvents	Yes - Add "Carcinogenic" warning
6	Toluene	C7H8	Common solvent; MP -95°C, BP 110.6°C [citation:6]	Often confused with benzene; lower toxicity but still a neurotoxin	Yes - Add "Neurotoxin - Ventilation Required" warning
7	Water	H2O	Universal solvent; MP 0°C, BP 100°C [citation:7]	Students must know exact reference points for calibrations	No - Standard reference point
8	Hydrogen Peroxide	H2O2	Decomposes above ~150°C; MP -20.2°C [citation:8]	Decomposes to O2 + H2O; concentration matters (3% vs 30% are very different)	Yes - Add "Decomposes on heating - use caution" warning
9	Sodium Carbonate	Na2CO3	Decomposes before boiling; MP 851°C [citation:9]	No true boiling point; confusion with decomposition vs boiling	Yes - Display "Decomposes, No True BP" clearly
10	Sodium Bicarbonate	NaHCO3	Decomposes at ~50-100°C (lowest on list) [citation:9]	Students may think it melts; actually decomposes to Na2CO3 + CO2 + H2O	Yes - Display "Decomposes at low temp - no true MP/BP"
11	Calcium Carbonate	CaCO3	Decomposes at ~840°C before melting [citation:9]	Most students assume all solids melt; they must learn about thermal decomposition	Yes - Display "Decomposes to CaO + CO2" note
12	Potassium Nitrate	KNO3	Oxidizer; MP 334°C [citation:11]	Can release O2 on heating; fire hazard	Yes - Add "Strong Oxidizer" warning
13	Sodium Nitrate	NaNO3	Decomposes at ~380°C to NaNO2 + O2 [citation:9]	Confused with KNO3 (similar properties but different uses)	Yes - Display "Decomposes - releases O2" warning
14	Ammonium Chloride	NH4Cl	Sublimes/decomposes at ~338°C to NH3 + HCl [citation:9]	No true liquid phase; students must understand sublimation	Yes - Display "Sublimes/Decomposes - no true BP" warning
15	Silver Nitrate	AgNO3	Light-sensitive; MP 212°C [citation:9]	Photodecomposes; must be stored properly; stains skin black	Yes - Add "Light-Sensitive - Store in dark" warning"""

notes = {}
for line in user_data.strip().split('\\n'):
    parts = line.split('\\t')
    if len(parts) >= 5:
        name = parts[1].strip()
        reason = parts[4].strip()
        notes[name.lower()] = reason

# water vs dihydrogen monoxide? Water isn't strictly 'water' in the json if it's 'Dihydrogen monoxide'. Let's map 'water' to 'dihydrogen monoxide' just in case.
notes['dihydrogen monoxide'] = notes.get('water', '')

with open('assets/data/chemicals.json', 'r', encoding='utf-8') as f:
    chemicals = json.load(f)

for chem in chemicals:
    name_lower = chem['name'].lower()
    if name_lower in notes:
        chem['note'] = notes[name_lower]
    else:
        # Default empty note or none
        chem['note'] = None

with open('assets/data/chemicals.json', 'w', encoding='utf-8') as f:
    json.dump(chemicals, f, indent=2, ensure_ascii=False)
