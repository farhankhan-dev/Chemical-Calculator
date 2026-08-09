import json
import os

user_data = """1	Ammonia	NH3	One of the most important industrial chemicals; fundamental to understanding hydrogen bonding and gas behavior at STP	MP: -77.7°C; exists as gas at STP due to weak intermolecular forces	BP: -33.3°C; hydrogen bonding elevates BP above PH3	High solubility in water due to hydrogen bonding (forming NH4OH)	Key precursor for fertilizers (urea, ammonium salts) and explosives; used in Ostwald process for HNO3 production
2	Ethanol	C2H5OH	The most important simple alcohol; serves as reference point for alcohol physical properties and reactivity	MP: -114.1°C; low MP due to small size and limited hydrogen bonding	BP: 78.4°C; significantly lower than water despite hydrogen bonding	Flammable; undergoes oxidation to acetaldehyde then acetic acid	Universal solvent for organic compounds; used as fuel, disinfectant, and chemical feedstock
3	Methanol	CH3OH	The simplest alcohol; critical case study for toxicity and metabolic conversion to formaldehyde/formic acid	MP: -97.6°C; very low due to minimal van der Waals interactions	BP: 64.7°C; lower than ethanol due to weaker intermolecular forces	Highly toxic; metabolized to formaldehyde (toxic) and formic acid (causes blindness/death)	Key industrial feedstock for formaldehyde, acetic acid, and MTBE production; used as fuel and solvent
4	Acetone	C3H6O	The simplest ketone; exemplifies polar aprotic solvent behavior and low boiling point hazard	MP: -94.7°C; low due to lack of hydrogen bonding capability	BP: 56.1°C; extremely low due to dipole-dipole interactions only (no H-bonding)	Flash point: -20°C; highly flammable with low vapor pressure	Widely used as solvent for plastics, paints, and pharmaceuticals; important in synthesis of bisphenol A and methyl methacrylate
5	Benzene	C6H6	The foundational aromatic hydrocarbon; exemplifies aromaticity (delocalized π-electrons) and stability paradox	MP: 5.5°C; relatively high due to efficient π-π stacking in crystal lattice	BP: 80.1°C; elevated due to strong π-π interactions	Classified as Group 1 carcinogen; metabolized to epoxide intermediates that bind to DNA	Parent compound for all aromatic chemistry; precursor to styrene, phenol, cyclohexane, and many pharmaceuticals
6	Toluene	C7H8	Methyl-substituted benzene; demonstrates effect of substituents on aromatic ring properties	MP: -95.0°C; methyl group disrupts π-π stacking (lower MP than benzene)	BP: 110.6°C; methyl group adds van der Waals interactions (higher BP than benzene)	Classified as neurotoxin; metabolized to hippuric acid (biomarker for exposure)	Precursor to TNT, benzoic acid, and polyurethanes; widely used as solvent and paint thinner
7	Water	H2O	The universal solvent; exhibits anomalous physical properties due to extensive hydrogen bonding network	MP: 0.0°C; abnormally high for a hydride of Group 16 due to H-bonding	BP: 100.0°C; extremely high for a small molecule (compare H2S = -60°C)	Highest heat capacity of any common liquid (4.18 J/g·K); maximum density at 4°C	Essential for all known life; primary solvent in biological and chemical systems; standard reference point for thermodynamics
8	Hydrogen Peroxide	H2O2	Classic example of thermodynamically unstable compound; decomposes via radical mechanism	MP: -0.4°C; slightly below water's MP due to altered H-bonding network	BP: 150.2°C; higher than water due to stronger H-bonding (more H-bond donors/acceptors)	Decomposes exothermically: 2H2O2 → 2H2O + O2 (ΔH = -98 kJ/mol); catalyzed by MnO2, Fe2+, and light	Key industrial bleaching agent (paper, textiles); used as disinfectant and rocket propellant (high-test peroxide)
9	Sodium Carbonate	Na2CO3	Classic salt that decomposes before boiling; illustrates difference between physical and chemical change	MP: 851°C; decomposes at 851°C to Na2O + CO2	No true BP; undergoes thermal decomposition before reaching boiling point	Highly hygroscopic; forms hydrates (Na2CO3·10H2O = washing soda)	Major industrial chemical (glass production); used in water softening, detergent, and pH adjustment in paper industry
10	Sodium Bicarbonate	NaHCO3	Most thermally labile common carbonate; decomposes at low temperature to Na2CO3 + CO2 + H2O	Decomposes at ~50-100°C (no true MP); loses H2O and CO2 sequentially	No true BP; decomposes chemically before melting	Amphoteric; reacts with both acids (releasing CO2) and bases	Key leavening agent in baking; used as antacid, fire extinguisher, and in photography; precursor to Na2CO3
11	Calcium Carbonate	CaCO3	The most abundant carbonate mineral; demonstrates thermal decomposition (calcination) and the carbon cycle	MP: 1339°C (CaO + CO2 begins at ~840°C); decomposes before true melting	No true BP; decomposes at ~840°C to CaO + CO2	Insoluble in water; dissolves in acidic solution (cave formation via CO2 + H2O → H2CO3)	Major component of limestone, marble, and chalk; critical in cement production (Portland cement) and carbon capture
12	Potassium Nitrate	KNO3	Classic oxidizer and component of gunpowder; decomposes thermally releasing O2	MP: 334°C; lower than other nitrates due to large cation size	No true BP; decomposes at ~400°C releasing O2 (2KNO3 → 2KNO2 + O2)	Strong oxidizer; forms gunpowder mixture with charcoal and sulfur (75% KNO3, 15% C, 10% S)	Fertilizer (source of N and K); used in fireworks, rocket propellants, and food preservation (curing meats)
13	Sodium Nitrate	NaNO3	Another classic nitrate salt; decomposition path differs from KNO3 and releases NOx gases	MP: 307°C; higher than KNO3 due to smaller Na+ cation (stronger ionic bonding)	No true BP; decomposes at ~380°C: 2NaNO3 → 2NaNO2 + O2 (continues to Na2O + NOx at higher T)	Strong oxidizer; hygroscopic (requires careful storage)	Major fertilizer (Chile saltpeter); used in glass production, explosives, and as food preservative
14	Ammonium Chloride	NH4Cl	Classic example of sublimation; no true liquid phase at 1 atm due to decomposition	No true MP; sublimation/decomposition at ~338°C to NH3(g) + HCl(g)	No true BP; decomposes to gases without melting (can recombine on cooling)	Dissolves endothermically in water; used as flux for soldering and as an electrolyte	Source of NH3 in thermal decomposition; used in dry cell batteries, as expectorant, and in textile printing
15	Silver Nitrate	AgNO3	Classic example of photochemical decomposition; light-sensitive ionic compound	MP: 212°C; relatively low for a nitrate salt (large Ag+ cation weakens ionic lattice)	No true BP; decomposes at ~440°C to Ag + NO2 + O2	Light-sensitive: 2AgNO3 → 2Ag + 2NO2 + O2 (photodecomposition; stains black)	Widely used in analytical chemistry (halide precipitation); precursor to AgCl, AgBr, and AgI; used in photography and as antimicrobial agent"""

notes = {}
for line in user_data.strip().split('\n'):
    parts = line.split('\t')
    if len(parts) >= 4:
        name = parts[1].strip()
        # Combine all parts from index 3 onwards as the reason
        reason = " • ".join(p.strip() for p in parts[3:] if p.strip())
        notes[name.lower()] = reason

notes['dihydrogen monoxide'] = notes.get('water', '')

file_path = 'assets/data/chemicals.json'

with open(file_path, 'r', encoding='utf-8') as f:
    chemicals = json.load(f)

for chem in chemicals:
    name_lower = chem['name'].lower()
    if name_lower in notes:
        chem['note'] = notes[name_lower]

with open(file_path, 'w', encoding='utf-8') as f:
    json.dump(chemicals, f, indent=2, ensure_ascii=False)

print("Notes updated successfully to v2.")
