// ---------------------------------------------------------------------------
// TauntBuddy Study Hub · exam + course dataset
// Every exam ships with full subject → unit → chapter names, a one-line
// pattern summary and planning metadata used by the plan generator.
// ---------------------------------------------------------------------------

export const EXAMS = [
  {
    id: "jee",
    name: "JEE Main + Advanced",
    tag: "Engineering",
    blurb: "The full PCM roadmap for Main & Advanced — concept first, PYQs always.",
    pattern: "Main: 75 Qs · 300 marks · Advanced: 2 papers · mixed types",
    months: 12,
    hoursPerDay: 6,
    subjects: [
      {
        name: "Physics",
        units: [
          { name: "Mechanics", chapters: ["Physical World, Units & Measurements", "Kinematics (Motion in 1D & 2D)", "Laws of Motion", "Work, Energy & Power", "Rotational Motion", "Gravitation", "Simple Harmonic Motion & Oscillations"] },
          { name: "Properties of Matter & Thermal Physics", chapters: ["Mechanical Properties of Solids", "Mechanical Properties of Fluids", "Thermal Properties of Matter", "Kinetic Theory of Gases", "Thermodynamics", "Heat Transfer"] },
          { name: "Electrodynamics", chapters: ["Electrostatics", "Capacitance", "Current Electricity", "Moving Charges & Magnetism", "Magnetism & Matter", "Electromagnetic Induction", "Alternating Current", "Electromagnetic Waves"] },
          { name: "Optics & Modern Physics", chapters: ["Ray Optics & Optical Instruments", "Wave Optics", "Dual Nature of Radiation & Matter", "Atoms", "Nuclei", "Semiconductor Electronics"] }
        ]
      },
      {
        name: "Chemistry",
        units: [
          { name: "Physical Chemistry", chapters: ["Some Basic Concepts of Chemistry (Mole Concept)", "Structure of Atom", "States of Matter: Gases & Liquids", "Chemical Thermodynamics", "Chemical & Ionic Equilibrium", "Electrochemistry", "Chemical Kinetics", "Surface Chemistry", "Solutions", "Redox Reactions"] },
          { name: "Inorganic Chemistry", chapters: ["Classification of Elements & Periodicity", "Chemical Bonding & Molecular Structure", "Hydrogen & s-Block Elements", "p-Block Elements (Groups 13–14)", "p-Block Elements (Groups 15–18)", "d & f-Block Elements", "Coordination Compounds", "General Principles of Isolation of Metals (Metallurgy)", "Environmental Chemistry"] },
          { name: "Organic Chemistry", chapters: ["Organic Chemistry: Basic Principles & Techniques", "General Organic Chemistry (Isomerism & Resonance)", "Hydrocarbons: Alkanes, Alkenes, Alkynes & Aromatics", "Haloalkanes & Haloarenes", "Alcohols, Phenols & Ethers", "Aldehydes & Ketones", "Carboxylic Acids & Derivatives", "Amines (Organic Nitrogen Compounds)", "Biomolecules", "Polymers", "Chemistry in Everyday Life"] }
        ]
      },
      {
        name: "Mathematics",
        units: [
          { name: "Algebra", chapters: ["Complex Numbers & Quadratic Equations", "Sequences & Series", "Permutations & Combinations", "Binomial Theorem", "Matrices", "Determinants", "Mathematical Induction & Reasoning"] },
          { name: "Calculus", chapters: ["Sets, Relations & Functions", "Limits, Continuity & Differentiability", "Differentiation & Methods", "Applications of Derivatives (Maxima, Minima, Tangents)", "Indefinite & Definite Integrals", "Applications of Integrals (Area Under Curves)", "Differential Equations"] },
          { name: "Coordinate Geometry & Vectors", chapters: ["Straight Lines & Pair of Lines", "Circles", "Conic Sections: Parabola, Ellipse & Hyperbola", "Three-Dimensional Geometry", "Vector Algebra"] },
          { name: "Trigonometry & Statistics", chapters: ["Trigonometric Ratios, Identities & Equations", "Inverse Trigonometric Functions", "Properties of Triangles, Heights & Distances", "Probability", "Statistics"] }
        ]
      }
    ]
  },
  {
    id: "neet",
    name: "NEET UG",
    tag: "Medical",
    blurb: "NCERT line-by-line for Biology, plus Physics & Chemistry that never panic.",
    pattern: "180 Qs · 720 marks · 3 hrs 20 min",
    months: 12,
    hoursPerDay: 6,
    subjects: [
      {
        name: "Biology",
        units: [
          { name: "Diversity in the Living World", chapters: ["The Living World", "Biological Classification", "Plant Kingdom", "Animal Kingdom"] },
          { name: "Structural Organisation", chapters: ["Morphology of Flowering Plants", "Anatomy of Flowering Plants", "Structural Organisation in Animals (Tissues, Frog & Cockroach)"] },
          { name: "Cell Structure & Function", chapters: ["Cell: The Unit of Life", "Biomolecules", "Cell Cycle & Cell Division"] },
          { name: "Plant Physiology", chapters: ["Transport in Plants", "Mineral Nutrition", "Photosynthesis in Higher Plants", "Respiration in Plants", "Plant Growth & Development"] },
          { name: "Human Physiology", chapters: ["Digestion & Absorption", "Breathing & Exchange of Gases", "Body Fluids & Circulation", "Excretory Products & Their Elimination", "Locomotion & Movement", "Neural Control & Coordination", "Chemical Coordination & Integration (Endocrine)"] },
          { name: "Reproduction", chapters: ["Sexual Reproduction in Flowering Plants", "Human Reproduction", "Reproductive Health"] },
          { name: "Genetics & Evolution", chapters: ["Principles of Inheritance & Variation", "Molecular Basis of Inheritance", "Evolution"] },
          { name: "Biology in Human Welfare", chapters: ["Human Health & Disease", "Strategies for Enhancement in Food Production", "Microbes in Human Welfare"] },
          { name: "Biotechnology", chapters: ["Biotechnology: Principles & Processes", "Biotechnology & Its Applications"] },
          { name: "Ecology & Environment", chapters: ["Organisms & Populations", "Ecosystem", "Biodiversity & Conservation", "Environmental Issues"] }
        ]
      },
      {
        name: "Chemistry",
        units: [
          { name: "Physical Chemistry", chapters: ["Some Basic Concepts of Chemistry", "Structure of Atom", "States of Matter", "Thermodynamics", "Equilibrium", "Redox Reactions", "Solutions", "Electrochemistry", "Chemical Kinetics"] },
          { name: "Inorganic Chemistry", chapters: ["Classification of Elements & Periodicity in Properties", "Chemical Bonding & Molecular Structure", "Hydrogen", "s-Block Elements", "p-Block Elements", "d & f-Block Elements", "Coordination Compounds", "Metallurgy"] },
          { name: "Organic Chemistry", chapters: ["Basic Principles & Techniques of Organic Chemistry", "Hydrocarbons", "Haloalkanes & Haloarenes", "Alcohols, Phenols & Ethers", "Aldehydes, Ketones & Carboxylic Acids", "Organic Compounds Containing Nitrogen", "Biomolecules", "Polymers", "Chemistry in Everyday Life", "Environmental Chemistry"] }
        ]
      },
      {
        name: "Physics",
        units: [
          { name: "Mechanics", chapters: ["Units & Measurements", "Motion in a Straight Line", "Motion in a Plane", "Laws of Motion", "Work, Energy & Power", "System of Particles & Rotational Motion", "Gravitation"] },
          { name: "Properties of Bulk Matter", chapters: ["Mechanical Properties of Solids", "Mechanical Properties of Fluids", "Thermal Properties of Matter", "Thermodynamics", "Kinetic Theory"] },
          { name: "Waves & Oscillations", chapters: ["Oscillations", "Waves"] },
          { name: "Electrodynamics & Optics", chapters: ["Electrostatics", "Current Electricity", "Moving Charges & Magnetism", "Electromagnetic Induction & Alternating Current", "Electromagnetic Waves", "Ray Optics & Optical Instruments", "Wave Optics", "Dual Nature of Radiation & Matter", "Atoms & Nuclei", "Electronic Devices"] }
        ]
      }
    ]
  },
  {
    id: "upsc",
    name: "UPSC CSE",
    tag: "Civil Services",
    blurb: "Prelims + Mains syllabus mapped paper by paper, with revision baked in.",
    pattern: "Prelims (GS + CSAT) → Mains 9 papers → Interview",
    months: 14,
    hoursPerDay: 8,
    subjects: [
      {
        name: "GS Paper 1",
        units: [
          { name: "History", chapters: ["Ancient Indian History", "Medieval Indian History", "Modern Indian History (1757–1857)", "Indian Freedom Struggle (1857–1947)", "Post-Independence Consolidation", "World History & Revolutions"] },
          { name: "Art & Culture", chapters: ["Indian Architecture & Sculpture", "Performing Arts: Dance, Music & Theatre", "Literature, Languages & Philosophy", "Paintings, Handicrafts & Cultural Institutions"] },
          { name: "Geography", chapters: ["Geomorphology", "Climatology", "Oceanography", "Indian Physical Geography", "World Mapping & Resources", "Economic & Human Geography"] },
          { name: "Indian Society", chapters: ["Indian Society & Diversity", "Role of Women & Women's Organisations", "Population, Urbanisation & Poverty", "Communalism, Regionalism & Secularism", "Globalisation & Social Empowerment"] }
        ]
      },
      {
        name: "GS Paper 2",
        units: [
          { name: "Polity & Constitution", chapters: ["Constitutional Framework & Preamble", "Fundamental Rights, DPSP & Duties", "Union Executive & Parliament", "Judiciary", "Federal System & Centre–State Relations", "Local Governance: Panchayati Raj & Municipalities", "Constitutional & Non-Constitutional Bodies"] },
          { name: "Governance", chapters: ["Good Governance & Transparency (RTI)", "Civil Services & Accountability", "E-Governance & Citizen Charters", "Welfare Schemes & Institutions", "Pressure Groups & Self-Help Groups"] },
          { name: "International Relations", chapters: ["India & Its Neighbourhood", "Bilateral & Global Groupings", "International Institutions & Treaties", "Indian Diaspora & Policies Affecting Interests"] }
        ]
      },
      {
        name: "GS Paper 3",
        units: [
          { name: "Economy", chapters: ["Economic Growth & Development", "Inclusive Growth & Budgeting", "Agriculture & Allied Sectors", "Industry & Infrastructure", "Banking, Money & RBI", "External Sector & Trade"] },
          { name: "Science, Environment & Security", chapters: ["Science & Technology Developments", "Environment, Ecology & Climate Change", "Disaster Management", "Internal Security & Extremism", "Cyber Security & Border Management"] }
        ]
      },
      {
        name: "GS Paper 4 + CSAT",
        units: [
          { name: "Ethics, Integrity & Aptitude", chapters: ["Ethics & Human Interface", "Attitude, Aptitude & Emotional Intelligence", "Moral Thinkers & Philosophers", "Probity in Governance & Case Studies"] },
          { name: "CSAT", chapters: ["Reading Comprehension", "Logical Reasoning & Analytical Ability", "Basic Numeracy (Class X Level)", "Data Interpretation & Decision Making"] }
        ]
      }
    ]
  },
  {
    id: "gate-cs",
    name: "GATE CS",
    tag: "Engineering PG",
    blurb: "Every CS subject in official weight order — theory + aptitude covered.",
    pattern: "65 Qs · 100 marks · 3 hrs (15 aptitude + 85 subject)",
    months: 8,
    hoursPerDay: 5,
    subjects: [
      {
        name: "Engineering Mathematics",
        units: [
          { name: "Discrete Mathematics", chapters: ["Propositional & First-Order Logic", "Sets, Relations & Functions", "Graph Theory & Combinatorics"] },
          { name: "Applied Mathematics", chapters: ["Linear Algebra", "Calculus", "Probability & Statistics"] }
        ]
      },
      {
        name: "Core Computer Science",
        units: [
          { name: "Data Structures & Algorithms", chapters: ["Data Structures: Arrays, Stacks, Queues & Linked Lists", "Trees, Heaps & Hashing", "Graph Algorithms", "Algorithm Design: Greedy, Divide & Conquer, Dynamic Programming", "Complexity Analysis & Asymptotic Notation"] },
          { name: "Theory of Computation & Compilers", chapters: ["Regular Languages & Finite Automata", "Context-Free Languages & Pushdown Automata", "Turing Machines & Undecidability", "Compiler Design: Lexical Analysis to Code Generation"] },
          { name: "Computer Systems", chapters: ["Digital Logic & Number Systems", "Computer Organisation & Architecture", "Operating Systems", "Databases & SQL", "Computer Networks"] }
        ]
      }
    ]
  },
  {
    id: "cat",
    name: "CAT",
    tag: "MBA",
    blurb: "VARC, DILR and Quant drilled section-wise with timed practice days.",
    pattern: "3 sections · 66 Qs · 2 hrs (40 min each)",
    months: 8,
    hoursPerDay: 4,
    subjects: [
      {
        name: "VARC",
        units: [
          { name: "Reading Comprehension & Verbal Ability", chapters: ["RC: Science & Technology Passages", "RC: Humanities & Philosophy Passages", "RC: Business & Economics Passages", "Para Jumbles & Para Completion", "Odd Sentence Out", "Para Summary", "Critical Reasoning"] }
        ]
      },
      {
        name: "DILR",
        units: [
          { name: "Data Interpretation & Logical Reasoning", chapters: ["Data Interpretation: Tables & Caselets", "Data Interpretation: Bar, Line & Pie Charts", "Logical Reasoning: Arrangements & Puzzles", "Logical Reasoning: Games & Tournaments", "Logical Reasoning: Venn Diagrams & Set Theory", "Logical Reasoning: Blood Relations, Directions & Series", "Logical Reasoning: Binary Logic & Cubes"] }
        ]
      },
      {
        name: "QA",
        units: [
          { name: "Quantitative Ability", chapters: ["Arithmetic: Percentages, Profit & Loss, Interest", "Arithmetic: Ratio, Averages & Mixtures", "Arithmetic: Time, Speed, Distance & Work", "Algebra: Equations, Inequalities & Functions", "Algebra: Progressions, Logarithms & Surds", "Geometry & Mensuration", "Trigonometry & Coordinate Geometry", "Number System", "Modern Maths: P&C, Probability & Set Theory"] }
        ]
      }
    ]
  },
  {
    id: "cbse12",
    name: "CBSE Class 12",
    tag: "Boards",
    blurb: "Board-perfect NCERT coverage for Physics, Chemistry & Maths.",
    pattern: "Theory 70 + Practical/IA 30 · 3 hrs per subject",
    months: 9,
    hoursPerDay: 5,
    subjects: [
      {
        name: "Physics",
        units: [
          { name: "Electrostatics & Current", chapters: ["Electric Charges & Fields", "Electrostatic Potential & Capacitance", "Current Electricity"] },
          { name: "Magnetism & Electromagnetic Induction", chapters: ["Moving Charges & Magnetism", "Magnetism & Matter", "Electromagnetic Induction", "Alternating Current", "Electromagnetic Waves"] },
          { name: "Optics", chapters: ["Ray Optics & Optical Instruments", "Wave Optics"] },
          { name: "Modern Physics", chapters: ["Dual Nature of Radiation & Matter", "Atoms", "Nuclei", "Semiconductor Electronics"] }
        ]
      },
      {
        name: "Chemistry",
        units: [
          { name: "Physical Chemistry", chapters: ["Solutions", "Electrochemistry", "Chemical Kinetics"] },
          { name: "Inorganic Chemistry", chapters: ["d & f-Block Elements", "Coordination Compounds"] },
          { name: "Organic Chemistry", chapters: ["Haloalkanes & Haloarenes", "Alcohols, Phenols & Ethers", "Aldehydes, Ketones & Carboxylic Acids", "Amines", "Biomolecules"] }
        ]
      },
      {
        name: "Mathematics",
        units: [
          { name: "Relations & Calculus", chapters: ["Relations & Functions", "Inverse Trigonometric Functions", "Continuity & Differentiability", "Applications of Derivatives", "Integrals", "Applications of Integrals", "Differential Equations"] },
          { name: "Algebra", chapters: ["Matrices", "Determinants"] },
          { name: "Vectors & 3D Geometry", chapters: ["Vectors", "Three-Dimensional Geometry"] },
          { name: "Linear Programming & Probability", chapters: ["Linear Programming", "Probability"] }
        ]
      }
    ]
  },
  {
    id: "ssc",
    name: "SSC CGL",
    tag: "Govt Job",
    blurb: "Tier 1 + Tier 2 syllabus with GA kept rolling till the exam day.",
    pattern: "Tier 1: 100 Qs · 200 marks · Tier 2: Paper 1 (3 sessions)",
    months: 6,
    hoursPerDay: 5,
    subjects: [
      {
        name: "Quantitative Aptitude",
        units: [
          { name: "Arithmetic", chapters: ["Number System & Simplification", "Percentage, Profit & Loss", "Ratio, Proportion & Mixtures", "Time, Speed, Distance & Work"] },
          { name: "Advanced Maths", chapters: ["Algebra", "Geometry", "Mensuration", "Trigonometry & Heights/Distances", "Data Interpretation"] }
        ]
      },
      {
        name: "English Comprehension",
        units: [
          { name: "Vocabulary & Grammar", chapters: ["Vocabulary: Synonyms, Antonyms & One-Word Substitution", "Idioms, Phrases & Spelling", "Grammar: Error Spotting & Sentence Improvement", "Fill in the Blanks & Cloze Test", "Reading Comprehension & Para Jumbles"] }
        ]
      },
      {
        name: "General Intelligence & Reasoning",
        units: [
          { name: "Verbal & Non-Verbal Reasoning", chapters: ["Analogy & Classification", "Series: Number, Alphabet & Figure", "Coding-Decoding", "Blood Relations & Direction Sense", "Syllogism & Statements/Conclusions", "Puzzles, Seating & Order/Ranking", "Non-Verbal: Mirror, Paper Folding & Embedded Figures"] }
        ]
      },
      {
        name: "General Awareness",
        units: [
          { name: "Static GK & Current Affairs", chapters: ["History of India", "Indian Polity & Constitution", "Geography: India & World", "General Science: Physics, Chemistry & Biology", "Economics & Budget", "Current Affairs & Static GK"] }
        ]
      }
    ]
  },
  {
    id: "clat",
    name: "CLAT",
    tag: "Law",
    blurb: "Passage-first prep for all five sections of the new CLAT pattern.",
    pattern: "120 Qs · 120 marks · 2 hrs (passage-based)",
    months: 8,
    hoursPerDay: 4,
    subjects: [
      {
        name: "English Language",
        units: [
          { name: "Comprehension & Usage", chapters: ["Reading Comprehension: Passage Techniques", "Inference, Tone & Central Idea", "Vocabulary in Context", "Sentence Correction & Grammar"] }
        ]
      },
      {
        name: "Current Affairs & GK",
        units: [
          { name: "News & Static GK", chapters: ["National News & Government Schemes", "International Affairs & Organisations", "Legal Current Affairs & Landmark Judgments", "Awards, Sports & Summits", "Static GK: History, Geography & Polity"] }
        ]
      },
      {
        name: "Legal Reasoning",
        units: [
          { name: "Principles & Application", chapters: ["Legal Principles & Fact Application", "Law of Torts", "Law of Contracts", "Constitutional Law Basics", "Criminal Law Basics (IPC & CrPC)"] }
        ]
      },
      {
        name: "Logical Reasoning",
        units: [
          { name: "Critical & Analytical Reasoning", chapters: ["Arguments: Strengthen & Weaken", "Assumptions, Conclusions & Inferences", "Analogies & Series", "Puzzles & Arrangements", "Critical Reasoning Passages"] }
        ]
      },
      {
        name: "Quantitative Techniques",
        units: [
          { name: "Numeracy & DI", chapters: ["Arithmetic: Ratios, Percentages & Averages", "Algebra Basics", "Data Interpretation: Tables & Graphs", "Mensuration & Basic Geometry"] }
        ]
      }
    ]
  }
];

export function getExam(id) {
  return EXAMS.find((e) => e.id === id) || null;
}

export function flattenTopics(exam) {
  const out = [];
  exam.subjects.forEach((s) => {
    s.units.forEach((u) => {
      u.chapters.forEach((c) => {
        out.push({ subject: s.name, unit: u.name, chapter: c });
      });
    });
  });
  return out;
}

export function chapterCount(exam) {
  return flattenTopics(exam).length;
}
