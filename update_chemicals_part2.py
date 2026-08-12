import json
import re

user_data = """1	Acetic acid	CH3COOH	60.052	60.052	Yes	Yes	Both MP and BP	Acetate	
2	Hydrochloric acid	HCl	36.458	36.458	Yes	Yes	Both MP and BP	Chloride	
3	Sulfuric acid	H2SO4	98.072	49.036	Yes	Yes	Both MP and BP	Sulfate	
4	Acetate	CH3COO-	59.044	59.044	No	N/A	Neither (Ionic Species)	Acetate	
5	Ammonia	NH3	17.031	17.031	Yes	Yes	Both MP and BP	Ammonium	
6	Nitric acid	HNO3	63.012	63.012	Yes	Yes	Both MP and BP	Nitrate	
7	Phosphoric acid	H3PO4	97.994	32.665	Yes	Yes	Both MP and BP	Phosphate	
8	Sodium phosphate	Na3PO4	163.94	54.647	Yes	Yes	Both MP and BP	Sodium/Phosphate	
9	Calcium carbonate	CaCO3	100.086	50.043	Yes	Decomposes	Has MP, No BP (Decomposes)	Calcium/Carbonate	
10	Ammonium sulfate	(NH4)2SO4	132.134	66.067	Yes	Yes	Both MP and BP	Ammonium/Sulfate	
11	Carbonic acid	H2CO3	62.024	31.012	Yes	Yes	Both MP and BP	Acid	
12	Sodium bicarbonate	NaHCO3	84.0066	84.0066	Yes	Decomposes	Has MP, No BP (Decomposes)	Sodium/Carbonate	
13	Sodium hydroxide	NaOH	39.997	39.997	Yes	Yes	Both MP and BP	Sodium/Hydroxide	
14	Calcium hydroxide	Ca(OH)2	74.092	37.046	Yes	Decomposes	Has MP, No BP (Decomposes)	Calcium/Hydroxide	
15	Ethanol	C2H5OH	46.069	46.069	Yes	Yes	Both MP and BP	Alcohol	
16	Hydrobromic acid	HBr	80.912	80.912	Yes	Yes	Both MP and BP	Bromide	
17	Nitrous acid	HNO2	47.013	47.013	Yes	Yes	Both MP and BP	Acid	
18	Potassium hydroxide	KOH	56.11	56.11	Yes	Yes	Both MP and BP	Potassium/Hydroxide	
19	Silver nitrate	AgNO3	169.872	169.872	Yes	Yes	Both MP and BP	Silver/Nitrate	
20	Sodium carbonate	Na2CO3	105.988	52.994	Yes	Decomposes	Has MP, No BP (Decomposes)	Sodium/Carbonate	
21	Sodium chloride	NaCl	58.44	58.44	Yes	Yes	Both MP and BP	Sodium/Chloride	
22	Cellulose	(C6H10O5)n	162.1406	162.1406	No	N/A	Has MP, No BP (Decomposes)	Polymer	MP not well-defined for polymers.
23	Magnesium hydroxide	Mg(OH)2	58.319	29.16	Yes	Decomposes	Has MP, No BP (Decomposes)	Magnesium/Hydroxide	
24	Methane	CH4	16.043	16.043	Yes	Yes	Both MP and BP	Hydrocarbon	
25	Nitrogen dioxide	NO2	46.005	46.005	Yes	Yes	Both MP and BP	Nitrogen Oxide	
26	Sodium nitrate	NaNO3	84.994	84.994	Yes	Decomposes	Has MP, No BP (Decomposes)	Sodium/Nitrate	Corrected: Decomposes at 380°C, no true BP.
27	Sulfurous acid	H2SO3	82.073	41.037	Yes	Yes	Both MP and BP	Sulfate	
28	Aluminium sulfate	Al2(SO4)3	342.15	57.025	Yes	Decomposes	Has MP, No BP (Decomposes)	Aluminum/Sulfate	
29	Aluminum oxide	Al2O3	101.96	16.993	Yes	Yes	Both MP and BP	Aluminum/Oxide	
30	Ammonium nitrate	NH4NO3	80.043	80.043	Yes	Decomposes	Has MP, No BP (Decomposes)	Ammonium/Nitrate	
31	Ammonium phosphate	(NH4)3PO4	149.087	49.696	No	N/A	Has MP, No BP (Decomposes)	Ammonium/Phosphate	
32	Barium hydroxide	Ba(OH)2	171.341	85.671	Yes	Yes	Both MP and BP	Barium/Hydroxide	
33	Carbon tetrachloride	CCl4	153.811	153.811	Yes	Yes	Both MP and BP	Chloride	
34	Citric acid	C6H8O7	192.123	64.041	Yes	Decomposes	Has MP, No BP (Decomposes)	Acid	
35	Hydrocyanic acid	HCN	27.026	27.026	Yes	Yes	Both MP and BP	Acid	
36	Salicylic Acid	C7H6O3	138.121	138.121	Yes	Decomposes	Has MP, No BP (Decomposes)	Acid	
37	Hydroiodic acid	HI	127.91	127.91	Yes	Yes	Both MP and BP	Iodide	
38	Hypochlorous acid	HClO	52.457	52.457	Yes	Yes	Both MP and BP	Chloride	
39	Iron iii oxide	Fe2O3	159.687	26.615	Yes	Decomposes	Has MP, No BP (Decomposes)	Oxide	
40	Magnesium phosphate	Mg3(PO4)2	262.855	43.809	Yes	Decomposes	Has MP, No BP (Decomposes)	Magnesium/Phosphate	
41	Sodium acetate	C2H3NaO2	82.0343	82.0343	Yes	Yes	Both MP and BP	Sodium/Acetate	
42	Sodium sulfate	Na2SO4	142.036	71.018	Yes	Yes	Both MP and BP	Sodium/Sulfate	
43	Sucrose	C12H22O11	342.2965	342.2965	Yes	Decomposes	Has MP, No BP (Decomposes)	Carbohydrate	
44	Potassium nitrate	KNO3	101.102	101.102	Yes	Decomposes	Has MP, No BP (Decomposes)	Potassium/Nitrate	
45	Ammonium bicarbonate	NH4HCO3	79.055	79.055	No	N/A	Has MP, No BP (Decomposes)	Ammonium/Carbonate	
46	Ammonium chloride	NH4Cl	53.489	53.489	Yes	Decomposes	Has MP, No BP (Decomposes)	Ammonium/Chloride	Corrected: Decomposes to NH3 + HCl, no true BP.
47	Ammonium hydroxide	NH4OH	35.046	35.046	No	N/A	Has MP, No BP (Decomposes)	Ammonium/Hydroxide	
48	Calcium nitrate	Ca(NO3)2	164.088	82.044	Yes	Decomposes	Has MP, No BP (Decomposes)	Calcium/Nitrate	
49	Calcium oxide	CaO	56.0774	28.0387	Yes	Yes	Both MP and BP	Calcium/Oxide	
50	Carbon monoxide	CO	28.01	28.01	Yes	Yes	Both MP and BP	Carbon Oxide	
51	Chlorine gas	Cl2	70.9	35.45	Yes	Yes	Both MP and BP	Element/Diatomic	
52	Phenol	C6H6O	94.11	94.11	Yes	Yes	Both MP and BP	Alcohol	
53	Hydrogen peroxide	H2O2	34.0147	17.0074	Yes	Yes	Both MP and BP	Peroxide	
54	Hydroxide	OH-	17.007	17.007	No	N/A	Neither (Ionic Species)	Hydroxide	
55	Magnesium chloride	MgCl2	95.211	47.6055	Yes	Yes	Both MP and BP	Magnesium/Chloride	
56	Potassium chloride	KCl	74.5513	74.5513	Yes	Yes	Both MP and BP	Potassium/Chloride	
57	Potassium iodide	KI	166.0028	166.0028	Yes	Yes	Both MP and BP	Potassium/Iodide	
58	Sulfur dioxide	SO2	64.066	32.033	Yes	Yes	Both MP and BP	Sulfur	
59	Glycerin	C3H8O3	92.09	92.09	Yes	Decomposes	Has MP, No BP (Decomposes)	Alcohol	
60	Barium nitrate	Ba(NO3)2	261.337	130.6685	Yes	Decomposes	Has MP, No BP (Decomposes)	Barium/Nitrate	
61	Calcium acetate	C4H6O4Ca	158.17	79.085	Yes	Decomposes	Has MP, No BP (Decomposes)	Calcium/Acetate	
62	Iron oxide	Fe2O3	159.69	26.615	Yes	Decomposes	Has MP, No BP (Decomposes)	Oxide	
63	Potassium carbonate	K2CO3	138.205	69.1025	Yes	Decomposes	Has MP, No BP (Decomposes)	Potassium/Carbonate	
64	Silver chloride	AgCl	143.318	143.318	Yes	Yes	Both MP and BP	Silver/Chloride	Corrected: Has clean MP (455°C) and BP (1547°C).
65	Sodium iodide	NaI	149.894	149.894	Yes	Yes	Both MP and BP	Sodium/Iodide	
66	Sodium oxide	Na2O	61.9789	30.9895	Yes	Yes	Both MP and BP	Sodium/Oxide	
67	Sodium sulfide	Na2S	78.0452	39.0226	Yes	Yes	Both MP and BP	Sodium/Sulfide	
68	Zinc nitrate	Zn(NO3)2	189.388	94.694	Yes	Decomposes	Has MP, No BP (Decomposes)	Zinc/Nitrate	
69	Phenolphthalein	C20H14O4	318.32	159.16	Yes	Decomposes	Has MP, No BP (Decomposes)	Indicator	
70	Magnesium nitrate	Mg(NO3)2	148.313	74.1565	Yes	Decomposes	Has MP, No BP (Decomposes)	Magnesium/Nitrate	
71	Silicon dioxide	SiO2	60.083	30.0415	Yes	Yes	Both MP and BP	Oxide	
72	Acetone	C3H6O	58.08	58.08	Yes	Yes	Both MP and BP	Ketone	
73	Hydroquinone	C6H6O2	110.11	55.055	Yes	Decomposes	Has MP, No BP (Decomposes)	Alcohol	
74	Pyridine	C5H5N	79.1	79.1	Yes	Yes	Both MP and BP	Organic Base	
75	Ammonium acetate	C2H3O2NH4	77.083	77.083	Yes	Decomposes	Has MP, No BP (Decomposes)	Ammonium/Acetate	
76	Xylene	C8H10	106.16	106.16	Yes	Yes	Both MP and BP	Hydrocarbon	
77	Barium sulfate	BaSO4	233.38	116.69	Yes	Decomposes	Has MP, No BP (Decomposes)	Barium/Sulfate	
78	Benzene	C6H6	78.11	78.11	Yes	Yes	Both MP and BP	Hydrocarbon	
79	Bicarbonate	CHO3-	61.016	61.016	No	N/A	Neither (Ionic Species)	Carbonate	
80	Chromate	CrO4-2	115.992	57.996	No	N/A	Neither (Ionic Species)	Chromate	
81	Methyl Ethyl Ketone	C4H8O	72.107	72.107	Yes	Yes	Both MP and BP	Ketone	
82	Cyanide	CN-	26.02	26.02	No	N/A	Neither (Ionic Species)	Cyanide	
83	Trichloroacetic acid	C2HCl3O2	163.38	163.38	Yes	Yes	Both MP and BP	Acid/Chloride	
84	Magnesium sulfate	MgSO4	120.361	60.1805	Yes	Decomposes	Has MP, No BP (Decomposes)	Magnesium/Sulfate	
85	Methanol	CH3OH	32.04	32.04	Yes	Yes	Both MP and BP	Alcohol	
86	Oxygen	O2	31.998	7.9995	Yes	Yes	Both MP and BP	Element/Diatomic	Corrected: Elemental oxygen is diatomic (O2).
87	Methylene blue	C16H18ClN3S	319.85	159.925	Yes	Decomposes	Has MP, No BP (Decomposes)	Dye	
88	Sodium sulfite	Na2SO3	126.043	63.0215	Yes	Decomposes	Has MP, No BP (Decomposes)	Sodium/Sulfate	
89	Sulfur trioxide	SO3	80.057	40.0285	Yes	Yes	Both MP and BP	Sulfur	
90	Aluminum phosphate	AlPO4	121.951	40.6503	Yes	Decomposes	Has MP, No BP (Decomposes)	Aluminum/Phosphate	
91	Stearic acid	C18H36O2	284.484	284.484	Yes	Decomposes	Has MP, No BP (Decomposes)	Acid	
92	Dinitrogen monoxide	N2O	44.013	44.013	Yes	Yes	Both MP and BP	Nitrogen Oxide	
93	Titanium dioxide	TiO2	79.865	19.966	Yes	Yes	Both MP and BP	Oxide	
94	Acetonitrile	C2H3N	41.053	41.053	Yes	Yes	Both MP and BP	Nitrile	
95	Oxalic acid	H2C2O4	90.03	45.015	Yes	Decomposes	Has MP, No BP (Decomposes)	Acid	
96	Potassium dichromate	K2Cr2O7	294.185	49.0308	Yes	Decomposes	Has MP, No BP (Decomposes)	Potassium/Chromate	
97	Sodium bromide	NaBr	102.894	102.894	Yes	Yes	Both MP and BP	Sodium/Bromide	
98	Sodium hypochlorite	NaClO	74.439	74.439	No	N/A	Has MP, No BP (Decomposes)	Sodium/Chloride	
99	Zinc acetate	Zn(CH3COO)2	183.468	91.734	Yes	Decomposes	Has MP, No BP (Decomposes)	Zinc/Acetate	
100	Zinc chloride	ZnCl2	136.286	68.143	Yes	Yes	Both MP and BP	Zinc/Chloride	
101	Zinc hydroxide	Zn(OH)2	99.424	49.712	Yes	Decomposes	Has MP, No BP (Decomposes)	Zinc/Hydroxide	
102	Magnesium carbonate	MgCO3	84.313	42.1565	Yes	Decomposes	Has MP, No BP (Decomposes)	Magnesium/Carbonate	
103	Potassium chlorate	KClO3	122.545	20.4242	Yes	Decomposes	Has MP, No BP (Decomposes)	Potassium/Chloride	
104	Hydrazine	N2H4	32.0452	16.0226	Yes	Yes	Both MP and BP	Nitrogen	
105	Ascorbic acid	C6H8O6	176.12	88.06	Yes	Decomposes	Has MP, No BP (Decomposes)	Acid	
106	Benzoic acid	C7H6O2	122.12	122.12	Yes	Decomposes	Has MP, No BP (Decomposes)	Acid	
107	Resorcinol	C6H6O2	110.1	55.05	Yes	Decomposes	Has MP, No BP (Decomposes)	Alcohol	
108	Chlorine	Cl2	70.9	35.45	Yes	Yes	Both MP and BP	Element/Diatomic	
109	Maleic acid	C4H4O4	116.072	58.036	Yes	Decomposes	Has MP, No BP (Decomposes)	Acid	
110	Sodium metabisulfite	Na2S2O5	190.107	95.0535	Yes	Decomposes	Has MP, No BP (Decomposes)	Sodium/Sulfate	
111	Acetamide	C2H5NO	59.068	59.068	Yes	Yes	Both MP and BP	Amide	
112	Sodium silicate	(Na2O)SiO2	122.062	61.031	Yes	Decomposes	Has MP, No BP (Decomposes)	Sodium/Oxide	
113	Nitrite	NO2-	46.005	46.005	No	N/A	Neither (Ionic Species)	Nitrate	
114	Phosphate	PO4-3	94.9714	31.6571	No	N/A	Neither (Ionic Species)	Phosphate	
115	Dichloromethane	CH2Cl2	84.93	84.93	Yes	Yes	Both MP and BP	Chloride	
116	Carbon Disulfide	CS2	76.13	76.13	Yes	Yes	Both MP and BP	Sulfur	
117	Potassium chromate	CrK2O4	194.189	97.0945	Yes	Decomposes	Has MP, No BP (Decomposes)	Potassium/Chromate	
118	Zinc sulfate	ZnSO4	161.436	80.718	Yes	Decomposes	Has MP, No BP (Decomposes)	Zinc/Sulfate	
119	Iodine	I2	253.809	126.9	Yes	Yes	Both MP and BP	Element/Diatomic	Corrected: Elemental iodine is diatomic (I2).
120	Tannic acid	C76H52O46	1701.19	170.119	No	N/A	Has MP, No BP (Decomposes)	Acid	
121	Aluminum	Al	26.982	8.994	Yes	Yes	Both MP and BP	Element	
122	Perchloric acid	HClO4	100.46	100.46	Yes	Decomposes	Has MP, No BP (Decomposes)	Acid/Chloride	
123	Hypochlorite	ClO-	51.449	51.449	No	N/A	Neither (Ionic Species)	Chloride	
124	Potassium Bromide	KBr	119.002	119.002	Yes	Yes	Both MP and BP	Potassium/Bromide	
125	Chromic acid	H2CrO4	118.01	59.005	Yes	Decomposes	Has MP, No BP (Decomposes)	Chromate	
126	Dihydrogen monoxide	H2O	18.0153	18.0153	Yes	Yes	Both MP and BP	Water	
127	Methyl acetate	C3H6O2	74.079	74.079	Yes	Yes	Both MP and BP	Acetate	
128	Dimethyl sulfoxide	C2H6OS	78.13	78.13	Yes	Yes	Both MP and BP	Sulfur	
129	Hexane	C6H14	86.18	86.18	Yes	Yes	Both MP and BP	Hydrocarbon	
130	Eugenol	C10H12O2	164.2	164.2	Yes	Yes	Both MP and BP	Alcohol	
131	Manganese dioxide	MnO2	86.9368	43.4684	Yes	Decomposes	Has MP, No BP (Decomposes)	Oxide	
132	Lactic acid	C3H6O3	90.078	90.078	Yes	Yes	Both MP and BP	Acid	
133	Sodium potassium tartrate	C4H4O6KNa·4H2O	282.1	141.05	Yes	Decomposes	Has MP, No BP (Decomposes)	Sodium/Potassium	
134	Hexamine	C6H12N4	140.186	140.186	Yes	Decomposes	Has MP, No BP (Decomposes)	Amine	
135	Lithium hydroxide	LiOH	23.95	23.95	Yes	Decomposes	Has MP, No BP (Decomposes)	Lithium/Hydroxide	
136	Phosphorus pentachloride	PCl5	208.24	41.648	Yes	Yes	Both MP and BP	Phosphorus/Chloride	
137	Potassium oxide	K2O	94.2	47.1	Yes	Decomposes	Has MP, No BP (Decomposes)	Potassium/Oxide	
138	Monopotassium phosphate	KH2PO4	136.084	136.084	Yes	Decomposes	Has MP, No BP (Decomposes)	Potassium/Phosphate	
139	Silver acetate	AgC2H3O2	166.91	166.91	Yes	Decomposes	Has MP, No BP (Decomposes)	Silver/Acetate	
140	Sodium citrate	Na3C6H5O7	258.06	86.02	Yes	Decomposes	Has MP, No BP (Decomposes)	Sodium/Acid	
141	Sodium fluoride	NaF	41.9882	41.9882	Yes	Yes	Both MP and BP	Sodium/Fluoride	
142	Sodium nitrite	NaNO2	68.9953	68.9953	Yes	Yes	Both MP and BP	Sodium/Nitrate	
143	Sulfate ion	SO4-2	96.06	48.03	No	N/A	Neither (Ionic Species)	Sulfate	
144	Barium carbonate	BaCO3	197.34	98.67	Yes	Decomposes	Has MP, No BP (Decomposes)	Barium/Carbonate	
145	Calcium iodide	CaI2	293.887	146.9435	Yes	Decomposes	Has MP, No BP (Decomposes)	Calcium/Iodide	
146	Hydrogen sulfate	HSO4-	97.064	97.064	No	N/A	Neither (Ionic Species)	Sulfate	
147	Lithium oxide	Li2O	29.88	14.94	Yes	Decomposes	Has MP, No BP (Decomposes)	Lithium/Oxide	
148	Dimethylglyoxime	C4H8N2O2	116.12	58.06	Yes	Decomposes	Has MP, No BP (Decomposes)	Organic	
149	Potassium Permanganate	KMnO4	158.034	31.6068	Yes	Decomposes	Has MP, No BP (Decomposes)	Potassium	
150	Silver phosphate	Ag3PO4	418.58	139.5267	Yes	Decomposes	Has MP, No BP (Decomposes)	Silver/Phosphate	
151	Ammonium bromide	NH4Br	97.943	97.943	Yes	Decomposes	Has MP, No BP (Decomposes)	Ammonium/Bromide	
152	Calcium phosphate	Ca3(PO4)2	310.18	51.6967	Yes	Decomposes	Has MP, No BP (Decomposes)	Calcium/Phosphate	
153	Dichromate	Cr2O7-2	215.985	35.998	No	N/A	Neither (Ionic Species)	Chromate	Corrected: Changed from potassium salt to bare dichromate ion.
154	Aluminum sulfide	Al2S3	150.158	25.0263	Yes	Decomposes	Has MP, No BP (Decomposes)	Aluminum/Sulfide	
155	Ammonium carbonate	(NH4)2CO3	96.086	48.043	Yes	Decomposes	Has MP, No BP (Decomposes)	Ammonium/Carbonate	
156	Barium chloride	BaCl2	208.23	104.115	Yes	Decomposes	Has MP, No BP (Decomposes)	Barium/Chloride	
157	Nitrogen monoxide	NO	30.006	10.002	Yes	Yes	Both MP and BP	Nitrogen Oxide	
158	Fructose	C6H12O6	180.16	180.16	Yes	Decomposes	Has MP, No BP (Decomposes)	Carbohydrate	
159	Magnesium iodide	MgI2	278.1139	139.057	Yes	Decomposes	Has MP, No BP (Decomposes)	Magnesium/Iodide	
160	Magnesium sulfide	MgS	56.38	28.19	Yes	Decomposes	Has MP, No BP (Decomposes)	Magnesium/Sulfide	
161	Ozone	O3	48	24	Yes	Yes	Both MP and BP	Element/Oxide	
162	Potassium cyanide	KCN	65.12	65.12	Yes	Decomposes	Has MP, No BP (Decomposes)	Potassium/Cyanide	
163	Silver oxide	Ag2O	231.735	115.8675	Yes	Decomposes	Has MP, No BP (Decomposes)	Silver/Oxide	
164	Sodium chromate	Na2CrO4	161.97	80.985	Yes	Decomposes	Has MP, No BP (Decomposes)	Sodium/Chromate	
165	Sodium peroxide	Na2O2	77.98	38.99	Yes	Decomposes	Has MP, No BP (Decomposes)	Sodium/Oxide	
166	Toluene	C7H8	92.14	92.14	Yes	Yes	Both MP and BP	Hydrocarbon	
167	Zinc carbonate	ZnCO3	125.388	62.694	Yes	Decomposes	Has MP, No BP (Decomposes)	Zinc/Carbonate	
168	Zinc phosphate	Zn3(PO4)2	386.11	64.3517	Yes	Decomposes	Has MP, No BP (Decomposes)	Zinc/Phosphate	
169	Zinc sulfide	ZnS	97.474	48.737	Yes	Decomposes	Has MP, No BP (Decomposes)	Zinc/Sulfide	
170	Para dichlorobenzene	C6H4Cl2	147.01	147.01	Yes	Yes	Both MP and BP	Chloride	
171	Boric acid	H3BO3	61.83	61.83	Yes	Decomposes	Has MP, No BP (Decomposes)	Acid	
172	Oxalate	C2O4-2	88.018	44.009	No	N/A	Neither (Ionic Species)	Acid	
173	Potassium bicarbonate	KHCO3	100.114	100.114	Yes	Decomposes	Has MP, No BP (Decomposes)	Potassium/Carbonate	
174	Potassium hypochlorite	KClO	90.55	90.55	Yes	Yes	Both MP and BP	Potassium/Chloride	
175	Potassium nitrite	KNO2	85.103	85.103	Yes	Decomposes	Has MP, No BP (Decomposes)	Potassium/Nitrate	
176	Bromothymol Blue	C27H28Br2O5S	624.384	624.384	Yes	Decomposes	Has MP, No BP (Decomposes)	Dye/Bromide	
177	Ammonium iodide	NH4I	144.94	144.94	Yes	Decomposes	Has MP, No BP (Decomposes)	Ammonium/Iodide	
178	Ammonium nitrite	NH4NO2	64.06	64.06	No	N/A	Has MP, No BP (Decomposes)	Ammonium/Nitrate	
179	Ammonium oxide	(NH4)2O	52.0763	26.0382	No	N/A	Has MP, No BP (Decomposes)	Ammonium/Oxide	
180	Argon gas	Ar	39.948	39.948	Yes	Yes	Both MP and BP	Element	
181	Barium bromide	BaBr2	297.14	148.57	Yes	Decomposes	Has MP, No BP (Decomposes)	Barium/Bromide	
182	Barium iodide	BaI2	391.136	195.568	Yes	Decomposes	Has MP, No BP (Decomposes)	Barium/Iodide	
183	Bromate	BrO3-	127.901	21.3168	No	N/A	Neither (Ionic Species)	Bromide	
184	Dinitrogen trioxide	N2O3	76.01	38.005	Yes	Yes	Both MP and BP	Nitrogen Oxide	
185	Ethylene glycol	C2H6O2	62.07	62.07	Yes	Yes	Both MP and BP	Alcohol	
186	Nickel sulfate	NiSO4	154.75	77.375	Yes	Yes	Both MP and BP	Nickel/Sulfate	
187	Helium	He	4.0026	4.0026	Yes	Yes	Both MP and BP	Element	
188	Iodide	I-	126.904	126.904	No	N/A	Neither (Ionic Species)	Iodide	
189	Lead ii acetate	Pb(C2H3O2)2	325.29	162.645	Yes	Decomposes	Has MP, No BP (Decomposes)	Lead/Acetate	
190	Lithium chloride	LiCl	42.394	42.394	Yes	Decomposes	Has MP, No BP (Decomposes)	Lithium/Chloride	
191	Phosphate ion	PO4-3	94.9714	31.6571	No	N/A	Neither (Ionic Species)	Phosphate	
192	Potassium fluoride	KF	58.0967	58.0967	Yes	Yes	Both MP and BP	Potassium/Fluoride	
193	Potassium sulfite	K2SO3	158.26	79.13	Yes	Decomposes	Has MP, No BP (Decomposes)	Potassium/Sulfate	
194	Silver carbonate	Ag2CO3	275.7453	137.8726	Yes	Decomposes	Has MP, No BP (Decomposes)	Silver/Carbonate	
195	Sodium cyanide	NaCN	49.0072	49.0072	Yes	Yes	Both MP and BP	Sodium/Cyanide	
196	Sodium nitride	Na3N	82.976	27.6587	Yes	Decomposes	Has MP, No BP (Decomposes)	Sodium/Nitride	
197	Strontium chloride	SrCl2	158.52	79.26	Yes	Decomposes	Has MP, No BP (Decomposes)	Strontium/Chloride	
198	Strontium nitrate	Sr(NO3)2	211.628	105.814	Yes	Decomposes	Has MP, No BP (Decomposes)	Strontium/Nitrate	
199	Urea	CH4N2O	60.056	60.056	Yes	Decomposes	Has MP, No BP (Decomposes)	Organic	
200	Bleach	NaClO	74.439	74.439	No	N/A	Has MP, No BP (Decomposes)	Sodium/Chloride	
201	Lithium bromide	LiBr	86.844	86.844	Yes	Decomposes	Has MP, No BP (Decomposes)	Lithium/Bromide	
202	Aluminum fluoride	AlF3	83.9767	27.9922	Yes	Decomposes	Has MP, No BP (Decomposes)	Aluminum/Fluoride	
203	Barium fluoride	BaF2	175.34	87.67	Yes	Decomposes	Has MP, No BP (Decomposes)	Barium/Fluoride	
204	Butanoic acid	C4H8O2	88.11	88.11	Yes	Yes	Both MP and BP	Acid	
205	Calcium hydride	CaH2	42.094	21.047	Yes	Decomposes	Has MP, No BP (Decomposes)	Calcium/Hydride	
206	Copper ii carbonate	CuCO3	123.55	61.775	Yes	Decomposes	Has MP, No BP (Decomposes)	Copper/Carbonate	
207	Fluorine	F2	37.997	18.9984	Yes	Yes	Both MP and BP	Element/Diatomic	Corrected: Elemental fluorine is diatomic (F2).
208	Lithium phosphate	Li3PO4	115.79	38.5967	Yes	Decomposes	Has MP, No BP (Decomposes)	Lithium/Phosphate	
209	Glycerol	C3H8O3	92.0938	92.0938	Yes	Decomposes	Has MP, No BP (Decomposes)	Alcohol	
210	Hypobromous acid	HBrO	96.911	96.911	Yes	Yes	Both MP and BP	Bromide	
211	Hypoiodous acid	HIO	143.89	143.89	Yes	Yes	Both MP and BP	Iodide	
212	Lead iodide	PbI2	461.01	230.505	Yes	Decomposes	Has MP, No BP (Decomposes)	Lead/Iodide	
213	Lithium iodide	LiI	133.844	133.844	Yes	Decomposes	Has MP, No BP (Decomposes)	Lithium/Iodide	
214	Magnesium oxide	MgO	40.3044	20.1522	Yes	Yes	Both MP and BP	Magnesium/Oxide	
215	Urethane	C3H7NO2	89.09	89.09	Yes	Yes	Both MP and BP	Organic	
216	Nickel nitrate	Ni(NO3)2	182.703	91.3515	Yes	Decomposes	Has MP, No BP (Decomposes)	Nickel/Nitrate	
217	Sodium dichromate	Na2Cr2O7	261.97	43.6617	Yes	Decomposes	Has MP, No BP (Decomposes)	Sodium/Chromate	
218	Tartaric acid	C4H6O6	150.087	75.0435	Yes	Decomposes	Has MP, No BP (Decomposes)	Acid	
219	Zinc iodide	ZnI2	319.22	159.61	Yes	Decomposes	Has MP, No BP (Decomposes)	Zinc/Iodide	
220	Bromine	Br2	159.808	79.904	Yes	Yes	Both MP and BP	Element/Diatomic	Corrected: Elemental bromine is diatomic (Br2).
221	Aluminum bromide	AlBr3	266.69	88.8967	Yes	Decomposes	Has MP, No BP (Decomposes)	Aluminum/Bromide	
222	Sodium Percarbonate	C2H6Na4O12	314.018	78.505	Yes	Yes	Both MP and BP	Sodium/Carbonate	
223	Nickel acetate	C4H6O4Ni	176.781	88.391	Yes	Decomposes	Has MP, No BP (Decomposes)	Nickel/Acetate	
224	Sodium Thiosulfate	Na2S2O3	158.11	158.11	Yes	Decomposes	Has MP, No BP (Decomposes)	Sodium/Sulfate	
225	Acetaldehyde	C2H4O	44.05	44.05	Yes	Yes	Both MP and BP	Aldehyde	
226	Copper sulfate	CuSO4	159.609	79.8045	Yes	Decomposes	Has MP, No BP (Decomposes)	Copper/Sulfate	
227	Mannitol	C6H14O6	182.172	182.172	Yes	Decomposes	Has MP, No BP (Decomposes)	Alcohol	
228	Calcium Chloride	CaCl2	110.98	55.49	Yes	Decomposes	Has MP, No BP (Decomposes)	Calcium/Chloride	
229	Monosodium Glutamate	C5H8NO4Na	169.111	169.111	No	N/A	Has MP, No BP (Decomposes)	Sodium/Acid	
230	Polystyrene	(C8H8)n	104.1	104.1	No	N/A	Has MP, No BP (Decomposes)	Polymer	MP not well-defined for polymers.
231	Calcium Carbide	CaC2	64.099	32.0495	Yes	Decomposes	Has MP, No BP (Decomposes)	Calcium/Carbide	
232	Tetrachloroethylene	C2Cl4	165.83	165.83	Yes	Yes	Both MP and BP	Chloride	
233	Sodium Chlorate	NaClO3	106.44	17.74	Yes	Decomposes	Has MP, No BP (Decomposes)	Sodium/Chloride	
234	Potassium Iodate	KIO3	214.001	35.6668	Yes	Decomposes	Has MP, No BP (Decomposes)	Potassium/Iodide	
235	Lead Acetate	Pb(C2H3O2)2	325.29	162.645	Yes	Decomposes	Has MP, No BP (Decomposes)	Lead/Acetate	
236	Potassium Thiocyanate	KSCN	97.181	97.181	Yes	Decomposes	Has MP, No BP (Decomposes)	Potassium/Cyanide	
237	Butane	C4H10	58.12	58.12	Yes	Yes	Both MP and BP	Hydrocarbon	
238	Maltose	C12H22O11	342.3	342.3	Yes	Decomposes	Has MP, No BP (Decomposes)	Carbohydrate	
239	Polyurethane Foam	C27H36N2O10	548.589	548.589	No	N/A	Has MP, No BP (Decomposes)	Polymer	
240	Formaldehyde	CH2O	30.031	30.031	Yes	Yes	Both MP and BP	Aldehyde	
241	Formic Acid	HCOOH	46.03	46.03	Yes	Yes	Both MP and BP	Acid	
242	Sulfur Hexafluoride	SF6	146.06	146.06	Yes	Yes	Both MP and BP	Sulfur/Fluoride	
243	Phosphorus Trichloride	PCl3	137.33	45.7767	Yes	Yes	Both MP and BP	Phosphorus/Chloride	
244	Ethane	C2H6	30.07	30.07	Yes	Yes	Both MP and BP	Hydrocarbon	
245	Dinitrogen Pentoxide	N2O5	108.009	108.009	Yes	Yes	Both MP and BP	Nitrogen Oxide	
246	Phosphorous Acid	H3PO3	82	41	Yes	Decomposes	Has MP, No BP (Decomposes)	Acid/Phosphorus	
247	Potassium Ferrocyanide	K4Fe(CN)6	368.35	368.35	Yes	Decomposes	Has MP, No BP (Decomposes)	Potassium/Cyanide	
248	Xenon Difluoride	XeF2	169.29	84.645	Yes	Yes	Both MP and BP	Element/Fluoride	
249	Diatomic Bromine	Br2	159.808	79.904	Yes	Yes	Both MP and BP	Element/Diatomic	
250	Phenyl	C6H5	77.106	77.106	No	N/A	Neither (Unstable Radical)	Organic Radical	
251	Phosphorus Triiodide	PI3	411.6872	137.229	Yes	Yes	Both MP and BP	Phosphorus/Iodide	
252	Peroxydisulfuric Acid	H2S2O8	194.14	97.07	Yes	Decomposes	Has MP, No BP (Decomposes)	Acid/Sulfate	
253	Dipotassium Phosphate	K2HPO4	174.2	87.1	Yes	Decomposes	Has MP, No BP (Decomposes)	Potassium/Phosphate	
254	Aluminium hydroxide	Al(OH)3	78	26	Yes	Decomposes	Has MP, No BP (Decomposes)	Aluminum/Hydroxide	
255	Ammonium persulfate	(NH4)2S2O8	228.18	114.09	Yes	Decomposes	Has MP, No BP (Decomposes)	Ammonium/Sulfate	
256	Sodium borate	Na2[B4O5(OH)4]·8H2O	381.363	190.682	Yes	Decomposes	Has MP, No BP (Decomposes)	Sodium/Borate	
257	Chloroacetic acid	C2H3O2Cl	94.49	94.49	Yes	Yes	Both MP and BP	Acid/Chloride	
258	Potassium acetate	CH3CO2K	98.142	98.142	Yes	Yes	Both MP and BP	Potassium/Acetate	
259	Barium oxide	BaO	153.326	76.663	Yes	Yes	Both MP and BP	Barium/Oxide	
260	Copper I Oxide	Cu2O	143.09	71.545	Yes	Decomposes	Has MP, No BP (Decomposes)	Copper/Oxide	
261	Copper Hydroxide	Cu(OH)2	97.561	48.7805	Yes	Decomposes	Has MP, No BP (Decomposes)	Copper/Hydroxide	
262	Tin Oxide	SnO2	150.708	37.677	Yes	Decomposes	Has MP, No BP (Decomposes)	Tin/Oxide	
263	Chlorine Trifluoride	ClF3	92.448	46.224	Yes	Yes	Both MP and BP	Chloride/Fluoride	
264	Ethylene	C2H4	28.054	28.054	Yes	Yes	Both MP and BP	Hydrocarbon	
265	Acetylene	C2H2	26.038	26.038	Yes	Yes	Both MP and BP	Hydrocarbon	
266	Chromic Oxide	Cr2O3	151.9904	25.3317	Yes	Decomposes	Has MP, No BP (Decomposes)	Chromate/Oxide	
267	Sodium bisulfate	NaHSO4	120.06	120.06	Yes	Decomposes	Has MP, No BP (Decomposes)	Sodium/Sulfate	
268	Copper II chloride	CuCl2	134.45	67.225	Yes	Decomposes	Has MP, No BP (Decomposes)	Copper/Chloride	
269	Mercuric chloride	HgCl2	271.52	135.76	Yes	Decomposes	Has MP, No BP (Decomposes)	Mercury/Chloride	
270	Tin II chloride	SnCl2	189.6	94.8	Yes	Decomposes	Has MP, No BP (Decomposes)	Tin/Chloride	
271	Propane	C3H8	44.097	44.097	Yes	Yes	Both MP and BP	Hydrocarbon	
272	Lead IV oxide	PbO2	239.1988	119.5994	Yes	Decomposes	Has MP, No BP (Decomposes)	Lead/Oxide"""

with open('assets/data/chemicals.json', 'r', encoding='utf-8') as f:
    chemicals = json.load(f)

updates = {}
for line in user_data.strip().split('\\n'):
    parts = line.split('\\t')
    if len(parts) >= 9:
        # Some rows might have 10 columns if there's a note.
        # Format is ID | Name | Formula | MW | EW | MP Status | BP Status | Extra Status | Category | [Note]
        
        # We need to map the ID to find the record, OR find by name since ID might change.
        # But for now we map by the old ID or old name. The JSON still has old IDs right now.
        try:
            cid = int(parts[0])
            name = parts[1].strip()
            
            # Extract eq weight if provided and valid.
            eq_weight_str = parts[4].strip()
            eq_weight = None
            if eq_weight_str.replace('.','',1).isdigit():
                eq_weight = float(eq_weight_str)
                
            category = parts[8].strip()
            
            updates[name.lower()] = {
                'category': category,
                'equivalentWeight': eq_weight
            }
        except:
            continue

# Apply updates based on name (case insensitive) to be robust.
for chem in chemicals:
    name_lower = chem['name'].lower()
    if name_lower in updates:
        up = updates[name_lower]
        chem['category'] = up['category']
        if up['equivalentWeight'] is not None:
            chem['equivalentWeight'] = up['equivalentWeight']

# Ensure Sodium Phosphate has exact EW 54.647
for chem in chemicals:
    if chem['name'].lower() == 'sodium phosphate':
        chem['equivalentWeight'] = 54.647

# Now sort chemicals alphabetically by name
chemicals.sort(key=lambda x: x['name'].lower())

# Reassign IDs from 1 to N sequentially
for i, chem in enumerate(chemicals):
    chem['id'] = i + 1

with open('assets/data/chemicals.json', 'w', encoding='utf-8') as f:
    json.dump(chemicals, f, indent=2, ensure_ascii=False)
