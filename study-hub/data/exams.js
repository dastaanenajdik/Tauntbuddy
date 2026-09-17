export const EXAMS = [
  {
    id: "jee",
    name: "JEE Main + Advanced",
    tag: "Engineering",
    months: 12,
    hoursPerDay: 6,
    subjects: [
      {
        name: "Physics",
        units: [
          { name: "Mechanics", chapters: ["Kinematics", "Laws of Motion", "Work Energy Power", "Rotational Motion", "Gravitation", "SHM"] },
          { name: "Thermal Physics", chapters: ["Kinetic Theory", "Thermodynamics", "Heat Transfer"] },
          { name: "Electrodynamics", chapters: ["Electrostatics", "Current Electricity", "Magnetism", "EMI", "AC", "EM Waves"] },
          { name: "Optics & Modern", chapters: ["Ray Optics", "Wave Optics", "Dual Nature", "Atoms Nuclei", "Semiconductors"] }
        ]
      },
      {
        name: "Chemistry",
        units: [
          { name: "Physical", chapters: ["Mole Concept", "Atomic Structure", "Chemical Bonding", "Thermodynamics", "Equilibrium", "Electrochemistry", "Kinetics"] },
          { name: "Inorganic", chapters: ["Periodic Table", "s-block", "p-block", "d-f block", "Coordination Compounds"] },
          { name: "Organic", chapters: ["GOC", "Hydrocarbons", "Haloalkanes", "Alcohols Phenols", "Aldehydes Ketones", "Amines", "Biomolecules"] }
        ]
      },
      {
        name: "Mathematics",
        units: [
          { name: "Algebra", chapters: ["Quadratic Equations", "Complex Numbers", "Sequences Series", "Binomial", "Permutations", "Matrices Determinants"] },
          { name: "Calculus", chapters: ["Limits Continuity", "Differentiation", "Application of Derivatives", "Integrals", "Differential Equations"] },
          { name: "Coordinate & Vector", chapters: ["Straight Line", "Circles", "Conic Sections", "3D Geometry", "Vectors"] },
          { name: "Others", chapters: ["Trigonometry", "Probability", "Statistics"] }
        ]
      }
    ]
  },
  {
    id: "neet",
    name: "NEET UG",
    tag: "Medical",
    months: 12,
    hoursPerDay: 6,
    subjects: [
      {
        name: "Biology",
        units: [
          { name: "Diversity", chapters: ["Living World", "Biological Classification", "Plant Kingdom", "Animal Kingdom"] },
          { name: "Structural Organisation", chapters: ["Morphology of Plants", "Anatomy of Plants", "Animal Tissues", "Frog Cockroach"] },
          { name: "Cell & Genetics", chapters: ["Cell Structure", "Cell Cycle", "Biomolecules", "Genetics", "Molecular Basis", "Evolution"] },
          { name: "Human Physiology", chapters: ["Digestion", "Breathing", "Circulation", "Excretion", "Locomotion", "Neural Control", "Chemical Coordination"] },
          { name: "Plant Physiology", chapters: ["Photosynthesis", "Respiration in Plants", "Plant Growth"] },
          { name: "Ecology & Biotech", chapters: ["Organisms & Populations", "Ecosystem", "Biodiversity", "Biotechnology"] }
        ]
      },
      {
        name: "Chemistry",
        units: [
          { name: "Physical", chapters: ["Some Basic Concepts", "Structure of Atom", "States of Matter", "Thermodynamics", "Equilibrium", "Redox"] },
          { name: "Inorganic", chapters: ["Classification of Elements", "p-block", "d-block", "Coordination"] },
          { name: "Organic", chapters: ["GOC", "Hydrocarbons", "Haloalkanes", "Oxygen Compounds", "Nitrogen Compounds", "Biomolecules"] }
        ]
      },
      {
        name: "Physics",
        units: [
          { name: "Mechanics", chapters: ["Units Dimensions", "Kinematics", "Laws of Motion", "Work Energy", "Rotational", "Gravitation"] },
          { name: "Waves & Heat", chapters: ["Oscillations", "Waves", "Thermal Properties", "Thermodynamics"] },
          { name: "Electro & Optics", chapters: ["Electrostatics", "Current", "Magnetism", "Optics", "Modern Physics"] }
        ]
      }
    ]
  },
  {
    id: "upsc",
    name: "UPSC CSE",
    tag: "Civil Services",
    months: 14,
    hoursPerDay: 8,
    subjects: [
      {
        name: "GS Paper 1",
        units: [
          { name: "History", chapters: ["Ancient India", "Medieval India", "Modern India", "Freedom Struggle", "World History"] },
          { name: "Art & Culture", chapters: ["Architecture", "Dance Music", "Literature", "Philosophy"] },
          { name: "Geography", chapters: ["Geomorphology", "Climatology", "Oceanography", "Indian Geography", "Resources"] },
          { name: "Society", chapters: ["Diversity", "Women", "Urbanisation", "Social Empowerment"] }
        ]
      },
      {
        name: "GS Paper 2",
        units: [
          { name: "Polity", chapters: ["Constitution", "Federalism", "Parliament", "Judiciary", "Rights", "Local Bodies"] },
          { name: "Governance", chapters: ["Transparency", "Civil Services", "E-governance", "Welfare schemes"] },
          { name: "IR", chapters: ["Neighbourhood", "Bilateral", "Multilateral", "Diaspora"] }
        ]
      },
      {
        name: "GS Paper 3",
        units: [
          { name: "Economy", chapters: ["Growth", "Budgeting", "Agriculture", "Industry", "Infrastructure"] },
          { name: "Science Env", chapters: ["S&T", "Environment", "Disaster Management", "Internal Security"] }
        ]
      },
      {
        name: "GS Paper 4 + CSAT",
        units: [
          { name: "Ethics", chapters: ["Thinkers", "Attitude", "Emotional Intelligence", "Case Studies"] },
          { name: "CSAT", chapters: ["Comprehension", "Logical Reasoning", "Quant Basics", "Data Interpretation"] }
        ]
      }
    ]
  },
  {
    id: "gate-cs",
    name: "GATE CS",
    tag: "Engineering PG",
    months: 8,
    hoursPerDay: 5,
    subjects: [
      {
        name: "Core CS",
        units: [
          { name: "DSA", chapters: ["Arrays Stacks Queues", "Trees Graphs", "Greedy DP", "Complexity"] },
          { name: "Algorithms & TOC", chapters: ["Sorting Searching", "DFA NFA", "CFG", "Turing Machines"] },
          { name: "Systems", chapters: ["OS", "DBMS", "CN", "COA"] },
          { name: "Theory", chapters: ["Compiler", "Digital Logic", "Discrete Maths", "Engineering Maths"] }
        ]
      }
    ]
  },
  {
    id: "cat",
    name: "CAT",
    tag: "MBA",
    months: 8,
    hoursPerDay: 4,
    subjects: [
      {
        name: "VARC",
        units: [{ name: "Verbal", chapters: ["RC Science", "RC Philosophy", "Para Jumbles", "Odd One Out", "Summary"] }]
      },
      {
        name: "DILR",
        units: [{ name: "Sets", chapters: ["Tables", "Games Tournaments", "Arrangements", "Venn", "Graphs"] }]
      },
      {
        name: "QA",
        units: [{ name: "Quant", chapters: ["Arithmetic", "Algebra", "Geometry", "Number System", "Modern Maths"] }]
      }
    ]
  },
  {
    id: "cbse12",
    name: "CBSE Class 12",
    tag: "Boards",
    months: 9,
    hoursPerDay: 5,
    subjects: [
      {
        name: "Physics",
        units: [
          { name: "Electrostatics & Current", chapters: ["Electric Charges", "Potential Capacitance", "Current Electricity"] },
          { name: "Magnetism & EMI", chapters: ["Moving Charges", "Magnetism Matter", "EMI", "AC", "EM Waves"] },
          { name: "Optics & Modern", chapters: ["Ray Optics", "Wave Optics", "Dual Nature", "Atoms", "Nuclei", "Semiconductors"] }
        ]
      },
      {
        name: "Chemistry",
        units: [
          { name: "Physical", chapters: ["Solutions", "Electrochemistry", "Chemical Kinetics"] },
          { name: "Inorganic", chapters: ["d-f Block", "Coordination", "p-block leftover"] },
          { name: "Organic", chapters: ["Haloalkanes", "Alcohols", "Aldehydes", "Amines", "Biomolecules"] }
        ]
      },
      {
        name: "Mathematics",
        units: [
          { name: "Relations Calculus", chapters: ["Relations Functions", "Inverse Trig", "Matrices", "Determinants", "Continuity", "Differentiation", "Integrals", "DE"] },
          { name: "Vectors Probability", chapters: ["Vectors", "3D", "LP", "Probability"] }
        ]
      }
    ]
  },
  {
    id: "ssc",
    name: "SSC CGL",
    tag: "Govt Job",
    months: 6,
    hoursPerDay: 5,
    subjects: [
      {
        name: "Tier 1+2",
        units: [
          { name: "Quant", chapters: ["Number System", "Algebra", "Geometry", "Mensuration", "Trig", "DI"] },
          { name: "English", chapters: ["Vocab", "Grammar", "RC", "Cloze"] },
          { name: "Reasoning", chapters: ["Series", "Coding", "Syllogism", "Puzzle"] },
          { name: "GA", chapters: ["History", "Polity", "Geo", "Science", "Current"] }
        ]
      }
    ]
  },
  {
    id: "clat",
    name: "CLAT",
    tag: "Law",
    months: 8,
    hoursPerDay: 4,
    subjects: [
      {
        name: "Papers",
        units: [
          { name: "English", chapters: ["RC", "Vocab in context", "Inference"] },
          { name: "GK Current", chapters: ["National", "International", "Legal news", "Awards"] },
          { name: "Legal Reasoning", chapters: ["Principles Facts", "Constitution basics", "Torts Contracts"] },
          { name: "Logical", chapters: ["Arguments", "Assumptions", "Puzzles"] },
          { name: "Quant", chapters: ["Arithmetic", "DI"] }
        ]
      }
    ]
  }
];

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
