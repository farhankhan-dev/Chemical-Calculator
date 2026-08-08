import json
import re

elements = {
    'H': 1, 'He': 2, 'Li': 3, 'Be': 4, 'B': 5, 'C': 6, 'N': 7, 'O': 8, 'F': 9, 'Ne': 10,
    'Na': 11, 'Mg': 12, 'Al': 13, 'Si': 14, 'P': 15, 'S': 16, 'Cl': 17, 'Ar': 18, 'K': 19, 'Ca': 20,
    'Sc': 21, 'Ti': 22, 'V': 23, 'Cr': 24, 'Mn': 25, 'Fe': 26, 'Co': 27, 'Ni': 28, 'Cu': 29, 'Zn': 30,
    'Ga': 31, 'Ge': 32, 'As': 33, 'Se': 34, 'Br': 35, 'Kr': 36, 'Rb': 37, 'Sr': 38, 'Y': 39, 'Zr': 40,
    'Ag': 47, 'Cd': 48, 'In': 49, 'Sn': 50, 'Sb': 51, 'Te': 52, 'I': 53, 'Xe': 54, 'Cs': 55, 'Ba': 56,
    'Pt': 78, 'Au': 79, 'Hg': 80, 'Tl': 81, 'Pb': 82, 'Bi': 83, 'Th': 90, 'U': 92, 'Pu': 94
}

with open('assets/data/chemicals.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

for item in data:
    formula = item.get('formula', '')
    # Remove numbers and charges like + - 2 3
    base_formula = re.sub(r'[\d⁺⁻\+\-\(\)₂₃₄₅₆₇₈₉₀]+', '', formula)
    if base_formula in elements:
        item['atomicNumber'] = elements[base_formula]
        item['atomicMass'] = item.get('molecularWeight')
    else:
        item['atomicNumber'] = None
        item['atomicMass'] = item.get('molecularWeight')

with open('assets/data/chemicals.json', 'w', encoding='utf-8') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
print('Updated chemicals.json')
