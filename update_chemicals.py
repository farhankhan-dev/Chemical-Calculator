import json
import re

user_data = """1	Acetic acid	CH3COOH	60.052	60.052	Yes	Yes	Both MP and BP	
2	Hydrochloric acid	HCl	36.458	36.458	Yes	Yes	Both MP and BP	
3	Sulfuric acid	H2SO4	98.072	49.036	Yes	Yes	Both MP and BP	
4	Acetate	CH3COO-	59.044	59.044	No	N/A	Neither (Ionic Species)	
5	Ammonia	NH3	17.031	17.031	Yes	Yes	Both MP and BP	
6	Nitric acid	HNO3	63.012	63.012	Yes	Yes	Both MP and BP	
7	Phosphoric acid	H3PO4	97.994	32.665	Yes	Yes	Both MP and BP	
8	Sodium phosphate	Na3PO4	163.94	54.647	Yes	Yes	Both MP and BP	
9	Calcium carbonate	CaCO3	100.086	50.043	Yes	Decomposes	Has MP, No BP (Decomposes)	
10	Ammonium sulfate	(NH4)2SO4	132.134	66.067	Yes	Yes	Both MP and BP	
11	Carbonic acid	H2CO3	62.024	31.012	Yes	Yes	Both MP and BP	
12	Sodium bicarbonate	NaHCO3	84.0066	84.0066	Yes	Decomposes	Has MP, No BP (Decomposes)	
13	Sodium hydroxide	NaOH	39.997	39.997	Yes	Yes	Both MP and BP	
14	Calcium hydroxide	Ca(OH)2	74.092	37.046	Yes	Decomposes	Has MP, No BP (Decomposes)	
15	Ethanol	C2H5OH	46.069	46.069	Yes	Yes	Both MP and BP	
16	Hydrobromic acid	HBr	80.912	80.912	Yes	Yes	Both MP and BP	
17	Nitrous acid	HNO2	47.013	47.013	Yes	Yes	Both MP and BP	
18	Potassium hydroxide	KOH	56.11	56.11	Yes	Yes	Both MP and BP	
19	Silver nitrate	AgNO3	169.872	169.872	Yes	Yes	Both MP and BP	
20	Sodium carbonate	Na2CO3	105.988	52.994	Yes	Decomposes	Has MP, No BP (Decomposes)	
21	Sodium chloride	NaCl	58.44	58.44	Yes	Yes	Both MP and BP	
22	Cellulose	(C6H10O5)n	162.1406	162.1406	No	N/A	Has MP, No BP (Decomposes)	MP not well-defined for polymers.
23	Magnesium hydroxide	Mg(OH)2	58.319	29.16	Yes	Decomposes	Has MP, No BP (Decomposes)	
24	Methane	CH4	16.043	16.043	Yes	Yes	Both MP and BP	
25	Nitrogen dioxide	NO2	46.005	46.005	Yes	Yes	Both MP and BP	
26	Sodium nitrate	NaNO3	84.994	84.994	Yes	Decomposes	Has MP, No BP (Decomposes)	Corrected: Decomposes at 380°C, no true BP.
27	Sulfurous acid	H2SO3	82.073	41.037	Yes	Yes	Both MP and BP	
28	Aluminium sulfate	Al2(SO4)3	342.15	57.025	Yes	Decomposes	Has MP, No BP (Decomposes)	
29	Aluminum oxide	Al2O3	101.96	16.993	Yes	Yes	Both MP and BP	
30	Ammonium nitrate	NH4NO3	80.043	80.043	Yes	Decomposes	Has MP, No BP (Decomposes)	
31	Ammonium phosphate	(NH4)3PO4	149.087	49.696	No	N/A	Has MP, No BP (Decomposes)	
32	Barium hydroxide	Ba(OH)2	171.341	85.671	Yes	Yes	Both MP and BP	
33	Carbon tetrachloride	CCl4	153.811	153.811	Yes	Yes	Both MP and BP	
34	Citric acid	C6H8O7	192.123	64.041	Yes	Decomposes	Has MP, No BP (Decomposes)	
35	Hydrocyanic acid	HCN	27.026	27.026	Yes	Yes	Both MP and BP	
36	Salicylic Acid	C7H6O3	138.121	138.121	Yes	Decomposes	Has MP, No BP (Decomposes)	
37	Hydroiodic acid	HI	127.91	127.91	Yes	Yes	Both MP and BP	
38	Hypochlorous acid	HClO	52.457	52.457	Yes	Yes	Both MP and BP	
39	Iron iii oxide	Fe2O3	159.687	26.615	Yes	Decomposes	Has MP, No BP (Decomposes)	
40	Magnesium phosphate	Mg3(PO4)2	262.855	43.809	Yes	Decomposes	Has MP, No BP (Decomposes)	
41	Sodium acetate	C2H3NaO2	82.0343	82.0343	Yes	Yes	Both MP and BP	
42	Sodium sulfate	Na2SO4	142.036	71.018	Yes	Yes	Both MP and BP	
43	Sucrose	C12H22O11	342.2965	342.2965	Yes	Decomposes	Has MP, No BP (Decomposes)	
44	Potassium nitrate	KNO3	101.102	101.102	Yes	Decomposes	Has MP, No BP (Decomposes)	
45	Ammonium bicarbonate	NH4HCO3	79.055	79.055	No	N/A	Has MP, No BP (Decomposes)	
46	Ammonium chloride	NH4Cl	53.489	53.489	Yes	Decomposes	Has MP, No BP (Decomposes)	Corrected: Decomposes to NH3 + HCl, no true BP.
47	Ammonium hydroxide	NH4OH	35.046	35.046	No	N/A	Has MP, No BP (Decomposes)	
48	Calcium nitrate	Ca(NO3)2	164.088	82.044	Yes	Decomposes	Has MP, No BP (Decomposes)	
49	Calcium oxide	CaO	56.0774	28.0387	Yes	Yes	Both MP and BP	
50	Carbon monoxide	CO	28.01	28.01	Yes	Yes	Both MP and BP	
51	Chlorine gas	Cl2	70.9	35.45	Yes	Yes	Both MP and BP	
52	Phenol	C6H6O	94.11	94.11	Yes	Yes	Both MP and BP	
53	Hydrogen peroxide	H2O2	34.0147	17.0074	Yes	Yes	Both MP and BP	
54	Hydroxide	OH-	17.007	17.007	No	N/A	Neither (Ionic Species)	
55	Magnesium chloride	MgCl2	95.211	47.6055	Yes	Yes	Both MP and BP	
56	Potassium chloride	KCl	74.5513	74.5513	Yes	Yes	Both MP and BP	
57	Potassium iodide	KI	166.0028	166.0028	Yes	Yes	Both MP and BP	
58	Sulfur dioxide	SO2	64.066	32.033	Yes	Yes	Both MP and BP	
59	Glycerin	C3H8O3	92.09	92.09	Yes	Decomposes	Has MP, No BP (Decomposes)	
60	Barium nitrate	Ba(NO3)2	261.337	130.6685	Yes	Decomposes	Has MP, No BP (Decomposes)	
61	Calcium acetate	C4H6O4Ca	158.17	79.085	Yes	Decomposes	Has MP, No BP (Decomposes)	
62	Iron oxide	Fe2O3	159.69	26.615	Yes	Decomposes	Has MP, No BP (Decomposes)	
63	Potassium carbonate	K2CO3	138.205	69.1025	Yes	Decomposes	Has MP, No BP (Decomposes)	
64	Silver chloride	AgCl	143.318	143.318	Yes	Yes	Both MP and BP	Corrected: Has clean MP (455°C) and BP (1547°C).
65	Sodium iodide	NaI	149.894	149.894	Yes	Yes	Both MP and BP	
66	Sodium oxide	Na2O	61.9789	30.9895	Yes	Yes	Both MP and BP	
67	Sodium sulfide	Na2S	78.0452	39.0226	Yes	Yes	Both MP and BP	
68	Zinc nitrate	Zn(NO3)2	189.388	94.694	Yes	Decomposes	Has MP, No BP (Decomposes)	
69	Phenolphthalein	C20H14O4	318.32	159.16	Yes	Decomposes	Has MP, No BP (Decomposes)	
70	Magnesium nitrate	Mg(NO3)2	148.313	74.1565	Yes	Decomposes	Has MP, No BP (Decomposes)	
71	Silicon dioxide	SiO2	60.083	30.0415	Yes	Yes	Both MP and BP	
72	Acetone	C3H6O	58.08	58.08	Yes	Yes	Both MP and BP	
73	Hydroquinone	C6H6O2	110.11	55.055	Yes	Decomposes	Has MP, No BP (Decomposes)	
74	Pyridine	C5H5N	79.1	79.1	Yes	Yes	Both MP and BP	
75	Ammonium acetate	C2H3O2NH4	77.083	77.083	Yes	Decomposes	Has MP, No BP (Decomposes)	
76	Xylene	C8H10	106.16	106.16	Yes	Yes	Both MP and BP	
77	Barium sulfate	BaSO4	233.38	116.69	Yes	Decomposes	Has MP, No BP (Decomposes)	
78	Benzene	C6H6	78.11	78.11	Yes	Yes	Both MP and BP	
79	Bicarbonate	CHO3-	61.016	61.016	No	N/A	Neither (Ionic Species)	
80	Chromate	CrO4-2	115.992	57.996	No	N/A	Neither (Ionic Species)	
81	Methyl Ethyl Ketone	C4H8O	72.107	72.107	Yes	Yes	Both MP and BP	
82	Cyanide	CN-	26.02	26.02	No	N/A	Neither (Ionic Species)	
83	Trichloroacetic acid	C2HCl3O2	163.38	163.38	Yes	Yes	Both MP and BP	
84	Magnesium sulfate	MgSO4	120.361	60.1805	Yes	Decomposes	Has MP, No BP (Decomposes)	
85	Methanol	CH3OH	32.04	32.04	Yes	Yes	Both MP and BP	
86	Oxygen	O2	31.998	7.9995	Yes	Yes	Both MP and BP	Corrected: Elemental oxygen is diatomic (O2).
87	Methylene blue	C16H18ClN3S	319.85	159.925	Yes	Decomposes	Has MP, No BP (Decomposes)	
88	Sodium sulfite	Na2SO3	126.043	63.0215	Yes	Decomposes	Has MP, No BP (Decomposes)	
89	Sulfur trioxide	SO3	80.057	40.0285	Yes	Yes	Both MP and BP	
90	Aluminum phosphate	AlPO4	121.951	40.6503	Yes	Decomposes	Has MP, No BP (Decomposes)	
91	Stearic acid	C18H36O2	284.484	284.484	Yes	Decomposes	Has MP, No BP (Decomposes)	
92	Dinitrogen monoxide	N2O	44.013	44.013	Yes	Yes	Both MP and BP	
93	Titanium dioxide	TiO2	79.865	19.966	Yes	Yes	Both MP and BP	
94	Acetonitrile	C2H3N	41.053	41.053	Yes	Yes	Both MP and BP	
95	Oxalic acid	H2C2O4	90.03	45.015	Yes	Decomposes	Has MP, No BP (Decomposes)	
96	Potassium dichromate	K2Cr2O7	294.185	49.0308	Yes	Decomposes	Has MP, No BP (Decomposes)	
97	Sodium bromide	NaBr	102.894	102.894	Yes	Yes	Both MP and BP	
98	Sodium hypochlorite	NaClO	74.439	74.439	No	N/A	Has MP, No BP (Decomposes)	
99	Zinc acetate	Zn(CH3COO)2	183.468	91.734	Yes	Decomposes	Has MP, No BP (Decomposes)	
100	Zinc chloride	ZnCl2	136.286	68.143	Yes	Yes	Both MP and BP	
101	Zinc hydroxide	Zn(OH)2	99.424	49.712	Yes	Decomposes	Has MP, No BP (Decomposes)	
102	Magnesium carbonate	MgCO3	84.313	42.1565	Yes	Decomposes	Has MP, No BP (Decomposes)	
103	Potassium chlorate	KClO3	122.545	20.4242	Yes	Decomposes	Has MP, No BP (Decomposes)	
104	Hydrazine	N2H4	32.0452	16.0226	Yes	Yes	Both MP and BP	
105	Ascorbic acid	C6H8O6	176.12	88.06	Yes	Decomposes	Has MP, No BP (Decomposes)	
106	Benzoic acid	C7H6O2	122.12	122.12	Yes	Decomposes	Has MP, No BP (Decomposes)	
107	Resorcinol	C6H6O2	110.1	55.05	Yes	Decomposes	Has MP, No BP (Decomposes)	
108	Chlorine	Cl2	70.9	35.45	Yes	Yes	Both MP and BP	
109	Maleic acid	C4H4O4	116.072	58.036	Yes	Decomposes	Has MP, No BP (Decomposes)	
110	Sodium metabisulfite	Na2S2O5	190.107	95.0535	Yes	Decomposes	Has MP, No BP (Decomposes)	
111	Acetamide	C2H5NO	59.068	59.068	Yes	Yes	Both MP and BP	
112	Sodium silicate	(Na2O)SiO2	122.062	61.031	Yes	Decomposes	Has MP, No BP (Decomposes)	
113	Nitrite	NO2-	46.005	46.005	No	N/A	Neither (Ionic Species)	
114	Phosphate	PO4-3	94.9714	31.6571	No	N/A	Neither (Ionic Species)	
115	Dichloromethane	CH2Cl2	84.93	84.93	Yes	Yes	Both MP and BP	
116	Carbon Disulfide	CS2	76.13	76.13	Yes	Yes	Both MP and BP	
117	Potassium chromate	CrK2O4	194.189	97.0945	Yes	Decomposes	Has MP, No BP (Decomposes)	
118	Zinc sulfate	ZnSO4	161.436	80.718	Yes	Decomposes	Has MP, No BP (Decomposes)	
119	Iodine	I2	253.809	126.9	Yes	Yes	Both MP and BP	Corrected: Elemental iodine is diatomic (I2).
120	Tannic acid	C76H52O46	1701.19	170.119	No	N/A	Has MP, No BP (Decomposes)	
121	Aluminum	Al	26.982	8.994	Yes	Yes	Both MP and BP	
122	Perchloric acid	HClO4	100.46	100.46	Yes	Decomposes	Has MP, No BP (Decomposes)	
123	Hypochlorite	ClO-	51.449	51.449	No	N/A	Neither (Ionic Species)	
124	Potassium Bromide	KBr	119.002	119.002	Yes	Yes	Both MP and BP	
125	Chromic acid	H2CrO4	118.01	59.005	Yes	Decomposes	Has MP, No BP (Decomposes)	
126	Dihydrogen monoxide	H2O	18.0153	18.0153	Yes	Yes	Both MP and BP	
127	Methyl acetate	C3H6O2	74.079	74.079	Yes	Yes	Both MP and BP	
128	Dimethyl sulfoxide	C2H6OS	78.13	78.13	Yes	Yes	Both MP and BP	
129	Hexane	C6H14	86.18	86.18	Yes	Yes	Both MP and BP	
130	Eugenol	C10H12O2	164.2	164.2	Yes	Yes	Both MP and BP	
131	Manganese dioxide	MnO2	86.9368	43.4684	Yes	Decomposes	Has MP, No BP (Decomposes)	
132	Lactic acid	C3H6O3	90.078	90.078	Yes	Yes	Both MP and BP	
133	Sodium potassium tartrate	C4H4O6KNa·4H2O	282.1	141.05	Yes	Decomposes	Has MP, No BP (Decomposes)	
134	Hexamine	C6H12N4	140.186	140.186	Yes	Decomposes	Has MP, No BP (Decomposes)	
135	Lithium hydroxide	LiOH	23.95	23.95	Yes	Decomposes	Has MP, No BP (Decomposes)	
136	Phosphorus pentachloride	PCl5	208.24	41.648	Yes	Yes	Both MP and BP	
137	Potassium oxide	K2O	94.2	47.1	Yes	Decomposes	Has MP, No BP (Decomposes)	
138	Monopotassium phosphate	KH2PO4	136.084	136.084	Yes	Decomposes	Has MP, No BP (Decomposes)	
139	Silver acetate	AgC2H3O2	166.91	166.91	Yes	Decomposes	Has MP, No BP (Decomposes)	
140	Sodium citrate	Na3C6H5O7	258.06	86.02	Yes	Decomposes	Has MP, No BP (Decomposes)	
141	Sodium fluoride	NaF	41.9882	41.9882	Yes	Yes	Both MP and BP	
142	Sodium nitrite	NaNO2	68.9953	68.9953	Yes	Yes	Both MP and BP	
143	Sulfate ion	SO4-2	96.06	48.03	No	N/A	Neither (Ionic Species)	
144	Barium carbonate	BaCO3	197.34	98.67	Yes	Decomposes	Has MP, No BP (Decomposes)	
145	Calcium iodide	CaI2	293.887	146.9435	Yes	Decomposes	Has MP, No BP (Decomposes)	
146	Hydrogen sulfate	HSO4-	97.064	97.064	No	N/A	Neither (Ionic Species)	
147	Lithium oxide	Li2O	29.88	14.94	Yes	Decomposes	Has MP, No BP (Decomposes)	
148	Dimethylglyoxime	C4H8N2O2	116.12	58.06	Yes	Decomposes	Has MP, No BP (Decomposes)	
149	Potassium Permanganate	KMnO4	158.034	31.6068	Yes	Decomposes	Has MP, No BP (Decomposes)	
150	Silver phosphate	Ag3PO4	418.58	139.5267	Yes	Decomposes	Has MP, No BP (Decomposes)	
151	Ammonium bromide	NH4Br	97.943	97.943	Yes	Decomposes	Has MP, No BP (Decomposes)	
152	Calcium phosphate	Ca3(PO4)2	310.18	51.6967	Yes	Decomposes	Has MP, No BP (Decomposes)	
153	Dichromate	Cr2O7-2	215.985	35.998	No	N/A	Neither (Ionic Species)	Corrected: Changed from potassium salt to bare dichromate ion.
154	Aluminum sulfide	Al2S3	150.158	25.0263	Yes	Decomposes	Has MP, No BP (Decomposes)	
155	Ammonium carbonate	(NH4)2CO3	96.086	48.043	Yes	Decomposes	Has MP, No BP (Decomposes)	
156	Barium chloride	BaCl2	208.23	104.115	Yes	Decomposes	Has MP, No BP (Decomposes)	
157	Nitrogen monoxide	NO	30.006	10.002	Yes	Yes	Both MP and BP	
158	Fructose	C6H12O6	180.16	180.16	Yes	Decomposes	Has MP, No BP (Decomposes)	
159	Magnesium iodide	MgI2	278.1139	139.057	Yes	Decomposes	Has MP, No BP (Decomposes)	
160	Magnesium sulfide	MgS	56.38	28.19	Yes	Decomposes	Has MP, No BP (Decomposes)	
161	Ozone	O3	48	24	Yes	Yes	Both MP and BP	
162	Potassium cyanide	KCN	65.12	65.12	Yes	Decomposes	Has MP, No BP (Decomposes)	
163	Silver oxide	Ag2O	231.735	115.8675	Yes	Decomposes	Has MP, No BP (Decomposes)	
164	Sodium chromate	Na2CrO4	161.97	80.985	Yes	Decomposes	Has MP, No BP (Decomposes)	
165	Sodium peroxide	Na2O2	77.98	38.99	Yes	Decomposes	Has MP, No BP (Decomposes)	
166	Toluene	C7H8	92.14	92.14	Yes	Yes	Both MP and BP	
167	Zinc carbonate	ZnCO3	125.388	62.694	Yes	Decomposes	Has MP, No BP (Decomposes)	
168	Zinc phosphate	Zn3(PO4)2	386.11	64.3517	Yes	Decomposes	Has MP, No BP (Decomposes)	
169	Zinc sulfide	ZnS	97.474	48.737	Yes	Decomposes	Has MP, No BP (Decomposes)	
170	Para dichlorobenzene	C6H4Cl2	147.01	147.01	Yes	Yes	Both MP and BP	
171	Boric acid	H3BO3	61.83	61.83	Yes	Decomposes	Has MP, No BP (Decomposes)	
172	Oxalate	C2O4-2	88.018	44.009	No	N/A	Neither (Ionic Species)	
173	Potassium bicarbonate	KHCO3	100.114	100.114	Yes	Decomposes	Has MP, No BP (Decomposes)	
174	Potassium hypochlorite	KClO	90.55	90.55	Yes	Yes	Both MP and BP	
175	Potassium nitrite	KNO2	85.103	85.103	Yes	Decomposes	Has MP, No BP (Decomposes)	
176	Bromothymol Blue	C27H28Br2O5S	624.384	624.384	Yes	Decomposes	Has MP, No BP (Decomposes)	
177	Ammonium iodide	NH4I	144.94	144.94	Yes	Decomposes	Has MP, No BP (Decomposes)	
178	Ammonium nitrite	NH4NO2	64.06	64.06	No	N/A	Has MP, No BP (Decomposes)	
179	Ammonium oxide	(NH4)2O	52.0763	26.0382	No	N/A	Has MP, No BP (Decomposes)	
180	Argon gas	Ar	39.948	39.948	Yes	Yes	Both MP and BP	
181	Barium bromide	BaBr2	297.14	148.57	Yes	Decomposes	Has MP, No BP (Decomposes)	
182	Barium iodide	BaI2	391.136	195.568	Yes	Decomposes	Has MP, No BP (Decomposes)	
183	Bromate	BrO3-	127.901	21.3168	No	N/A	Neither (Ionic Species)	
184	Dinitrogen trioxide	N2O3	76.01	38.005	Yes	Yes	Both MP and BP	
185	Ethylene glycol	C2H6O2	62.07	62.07	Yes	Yes	Both MP and BP	
186	Nickel sulfate	NiSO4	154.75	77.375	Yes	Yes	Both MP and BP	
187	Helium	He	4.0026	4.0026	Yes	Yes	Both MP and BP	
188	Iodide	I-	126.904	126.904	No	N/A	Neither (Ionic Species)	
189	Lead ii acetate	Pb(C2H3O2)2	325.29	162.645	Yes	Decomposes	Has MP, No BP (Decomposes)	
190	Lithium chloride	LiCl	42.394	42.394	Yes	Decomposes	Has MP, No BP (Decomposes)	
191	Phosphate ion	PO4-3	94.9714	31.6571	No	N/A	Neither (Ionic Species)	
192	Potassium fluoride	KF	58.0967	58.0967	Yes	Yes	Both MP and BP	
193	Potassium sulfite	K2SO3	158.26	79.13	Yes	Decomposes	Has MP, No BP (Decomposes)	
194	Silver carbonate	Ag2CO3	275.7453	137.8726	Yes	Decomposes	Has MP, No BP (Decomposes)	
195	Sodium cyanide	NaCN	49.0072	49.0072	Yes	Yes	Both MP and BP	
196	Sodium nitride	Na3N	82.976	27.6587	Yes	Decomposes	Has MP, No BP (Decomposes)	
197	Strontium chloride	SrCl2	158.52	79.26	Yes	Decomposes	Has MP, No BP (Decomposes)	
198	Strontium nitrate	Sr(NO3)2	211.628	105.814	Yes	Decomposes	Has MP, No BP (Decomposes)	
199	Urea	CH4N2O	60.056	60.056	Yes	Decomposes	Has MP, No BP (Decomposes)	
200	Bleach	NaClO	74.439	74.439	No	N/A	Has MP, No BP (Decomposes)	
201	Lithium bromide	LiBr	86.844	86.844	Yes	Decomposes	Has MP, No BP (Decomposes)	
202	Aluminum fluoride	AlF3	83.9767	27.9922	Yes	Decomposes	Has MP, No BP (Decomposes)	
203	Barium fluoride	BaF2	175.34	87.67	Yes	Decomposes	Has MP, No BP (Decomposes)	
204	Butanoic acid	C4H8O2	88.11	88.11	Yes	Yes	Both MP and BP	
205	Calcium hydride	CaH2	42.094	21.047	Yes	Decomposes	Has MP, No BP (Decomposes)	
206	Copper ii carbonate	CuCO3	123.55	61.775	Yes	Decomposes	Has MP, No BP (Decomposes)	
207	Fluorine	F2	37.997	18.9984	Yes	Yes	Both MP and BP	Corrected: Elemental fluorine is diatomic (F2).
208	Lithium phosphate	Li3PO4	115.79	38.5967	Yes	Decomposes	Has MP, No BP (Decomposes)	
209	Glycerol	C3H8O3	92.0938	92.0938	Yes	Decomposes	Has MP, No BP (Decomposes)	
210	Hypobromous acid	HBrO	96.911	96.911	Yes	Yes	Both MP and BP	
211	Hypoiodous acid	HIO	143.89	143.89	Yes	Yes	Both MP and BP	
212	Lead iodide	PbI2	461.01	230.505	Yes	Decomposes	Has MP, No BP (Decomposes)	
213	Lithium iodide	LiI	133.844	133.844	Yes	Decomposes	Has MP, No BP (Decomposes)	
214	Magnesium oxide	MgO	40.3044	20.1522	Yes	Yes	Both MP and BP	
215	Urethane	C3H7NO2	89.09	89.09	Yes	Yes	Both MP and BP	
216	Nickel nitrate	Ni(NO3)2	182.703	91.3515	Yes	Decomposes	Has MP, No BP (Decomposes)	
217	Sodium dichromate	Na2Cr2O7	261.97	43.6617	Yes	Decomposes	Has MP, No BP (Decomposes)	
218	Tartaric acid	C4H6O6	150.087	75.0435	Yes	Decomposes	Has MP, No BP (Decomposes)	
219	Zinc iodide	ZnI2	319.22	159.61	Yes	Decomposes	Has MP, No BP (Decomposes)	
220	Bromine	Br2	159.808	79.904	Yes	Yes	Both MP and BP	Corrected: Elemental bromine is diatomic (Br2).
221	Aluminum bromide	AlBr3	266.69	88.8967	Yes	Decomposes	Has MP, No BP (Decomposes)	
222	Sodium Percarbonate	C2H6Na4O12	314.018	78.505	Yes	Yes	Both MP and BP	
223	Nickel acetate	C4H6O4Ni	176.781	88.391	Yes	Decomposes	Has MP, No BP (Decomposes)	
224	Sodium Thiosulfate	Na2S2O3	158.11	158.11	Yes	Decomposes	Has MP, No BP (Decomposes)	
225	Acetaldehyde	C2H4O	44.05	44.05	Yes	Yes	Both MP and BP	
226	Copper sulfate	CuSO4	159.609	79.8045	Yes	Decomposes	Has MP, No BP (Decomposes)	
227	Mannitol	C6H14O6	182.172	182.172	Yes	Decomposes	Has MP, No BP (Decomposes)	
228	Calcium Chloride	CaCl2	110.98	55.49	Yes	Decomposes	Has MP, No BP (Decomposes)	
229	Monosodium Glutamate	C5H8NO4Na	169.111	169.111	No	N/A	Has MP, No BP (Decomposes)	
230	Polystyrene	(C8H8)n	104.1	104.1	No	N/A	Has MP, No BP (Decomposes)	MP not well-defined for polymers.
231	Calcium Carbide	CaC2	64.099	32.0495	Yes	Decomposes	Has MP, No BP (Decomposes)	
232	Tetrachloroethylene	C2Cl4	165.83	165.83	Yes	Yes	Both MP and BP	
233	Sodium Chlorate	NaClO3	106.44	17.74	Yes	Decomposes	Has MP, No BP (Decomposes)	
234	Potassium Iodate	KIO3	214.001	35.6668	Yes	Decomposes	Has MP, No BP (Decomposes)	
235	Lead Acetate	Pb(C2H3O2)2	325.29	162.645	Yes	Decomposes	Has MP, No BP (Decomposes)	
236	Potassium Thiocyanate	KSCN	97.181	97.181	Yes	Decomposes	Has MP, No BP (Decomposes)	
237	Butane	C4H10	58.12	58.12	Yes	Yes	Both MP and BP	
238	Maltose	C12H22O11	342.3	342.3	Yes	Decomposes	Has MP, No BP (Decomposes)	
239	Polyurethane Foam	C27H36N2O10	548.589	548.589	No	N/A	Has MP, No BP (Decomposes)	
240	Formaldehyde	CH2O	30.031	30.031	Yes	Yes	Both MP and BP	
241	Formic Acid	HCOOH	46.03	46.03	Yes	Yes	Both MP and BP	
242	Sulfur Hexafluoride	SF6	146.06	146.06	Yes	Yes	Both MP and BP	
243	Phosphorus Trichloride	PCl3	137.33	45.7767	Yes	Yes	Both MP and BP	
244	Ethane	C2H6	30.07	30.07	Yes	Yes	Both MP and BP	
245	Dinitrogen Pentoxide	N2O5	108.009	108.009	Yes	Yes	Both MP and BP	
246	Phosphorous Acid	H3PO3	82	41	Yes	Decomposes	Has MP, No BP (Decomposes)	
247	Potassium Ferrocyanide	K4Fe(CN)6	368.35	368.35	Yes	Decomposes	Has MP, No BP (Decomposes)	
248	Xenon Difluoride	XeF2	169.29	84.645	Yes	Yes	Both MP and BP	
249	Diatomic Bromine	Br2	159.808	79.904	Yes	Yes	Both MP and BP	
250	Phenyl	C6H5	77.106	77.106	No	N/A	Neither (Unstable Radical)	
251	Phosphorus Triiodide	PI3	411.6872	137.229	Yes	Yes	Both MP and BP	
252	Peroxydisulfuric Acid	H2S2O8	194.14	97.07	Yes	Decomposes	Has MP, No BP (Decomposes)	
253	Dipotassium Phosphate	K2HPO4	174.2	87.1	Yes	Decomposes	Has MP, No BP (Decomposes)	
254	Aluminium hydroxide	Al(OH)3	78	26	Yes	Decomposes	Has MP, No BP (Decomposes)	
255	Ammonium persulfate	(NH4)2S2O8	228.18	114.09	Yes	Decomposes	Has MP, No BP (Decomposes)	
256	Sodium borate	Na2[B4O5(OH)4]·8H2O	381.363	190.682	Yes	Decomposes	Has MP, No BP (Decomposes)	
257	Chloroacetic acid	C2H3O2Cl	94.49	94.49	Yes	Yes	Both MP and BP	
258	Potassium acetate	CH3CO2K	98.142	98.142	Yes	Yes	Both MP and BP	
259	Barium oxide	BaO	153.326	76.663	Yes	Yes	Both MP and BP	
260	Copper I Oxide	Cu2O	143.09	71.545	Yes	Decomposes	Has MP, No BP (Decomposes)	
261	Copper Hydroxide	Cu(OH)2	97.561	48.7805	Yes	Decomposes	Has MP, No BP (Decomposes)	
262	Tin Oxide	SnO2	150.708	37.677	Yes	Decomposes	Has MP, No BP (Decomposes)	
263	Chlorine Trifluoride	ClF3	92.448	46.224	Yes	Yes	Both MP and BP	
264	Ethylene	C2H4	28.054	28.054	Yes	Yes	Both MP and BP	
265	Acetylene	C2H2	26.038	26.038	Yes	Yes	Both MP and BP	
266	Chromic Oxide	Cr2O3	151.9904	25.3317	Yes	Decomposes	Has MP, No BP (Decomposes)	
267	Sodium bisulfate	NaHSO4	120.06	120.06	Yes	Decomposes	Has MP, No BP (Decomposes)	
268	Copper II chloride	CuCl2	134.45	67.225	Yes	Decomposes	Has MP, No BP (Decomposes)	
269	Mercuric chloride	HgCl2	271.52	135.76	Yes	Decomposes	Has MP, No BP (Decomposes)	
270	Tin II chloride	SnCl2	189.6	94.8	Yes	Decomposes	Has MP, No BP (Decomposes)	
271	Propane	C3H8	44.097	44.097	Yes	Yes	Both MP and BP	
272	Lead IV oxide	PbO2	239.1988	119.5994	Yes	Decomposes	Has MP, No BP (Decomposes)	"""

with open('assets/data/chemicals.json', 'r', encoding='utf-8') as f:
    chemicals = json.load(f)

# Parse user data
updates = {}
for line in user_data.strip().split('\\n'):
    parts = line.split('\\t')
    if len(parts) >= 8:
        cid = int(parts[0])
        formula = parts[2].strip()
        has_mp = parts[5].strip()
        has_bp = parts[6].strip()
        note = parts[8].strip() if len(parts) > 8 else ''
        updates[cid] = {
            'formula': formula,
            'has_mp': has_mp,
            'has_bp': has_bp,
            'note': note
        }

for chem in chemicals:
    cid = chem['id']
    if cid in updates:
        up = updates[cid]
        
        # apply specific notes
        if 'Decomposes at' in up['note'] or 'Decomposes to' in up['note']:
            chem['boilingPoint'] = None
        if 'clean MP (455°C) and BP (1547°C)' in up['note']:
            chem['meltingPoint'] = 455.0
            chem['boilingPoint'] = 1547.0
        
        # General rules based on has_bp / has_mp
        if up['has_bp'].lower() in ['decomposes', 'n/a', 'no']:
            chem['boilingPoint'] = None
        if up['has_mp'].lower() in ['n/a', 'no']:
            chem['meltingPoint'] = None
            
        # formula updates for diatomics
        if up['note'] and 'diatomic' in up['note'] and '(' in up['note']:
            m = re.search(r'\\((.*?)\\)', up['note'])
            if m:
                # convert e.g., O2 to O₂? The formula in JSON might use subscripts.
                pass # let's just use the logic for MP and BP first.

with open('assets/data/chemicals.json', 'w', encoding='utf-8') as f:
    json.dump(chemicals, f, indent=2, ensure_ascii=False)
