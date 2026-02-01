// Students Contract ABI (key functions only)
export const studentsAbi = [
    {
        type: "function",
        name: "applyForEnrollment",
        inputs: [
            { name: "studentName", type: "string" },
            { name: "facultyName", type: "string" },
            { name: "majorName", type: "string" },
        ],
        outputs: [],
        stateMutability: "nonpayable",
    },
    {
        type: "function",
        name: "enrollStudent",
        inputs: [],
        outputs: [],
        stateMutability: "payable",
    },
    {
        type: "function",
        name: "getStudent",
        inputs: [],
        outputs: [
            { name: "studentId", type: "string" },
            { name: "name", type: "string" },
            { name: "email", type: "string" },
            { name: "faculty", type: "string" },
            { name: "major", type: "string" },
            { name: "semester", type: "uint8" },
            { name: "status", type: "uint8" },
            { name: "validityPeriod", type: "string" },
        ],
        stateMutability: "nonpayable",
    },
    {
        type: "function",
        name: "applications",
        inputs: [
            { name: "", type: "address" },
            { name: "", type: "uint256" },
        ],
        outputs: [
            { name: "applicant", type: "address" },
            { name: "name", type: "string" },
            { name: "faculty", type: "string" },
            { name: "major", type: "string" },
            { name: "status", type: "uint8" },
        ],
        stateMutability: "view",
    },
    {
        type: "function",
        name: "isOpen",
        inputs: [],
        outputs: [{ name: "", type: "bool" }],
        stateMutability: "view",
    },
    {
        type: "function",
        name: "hasGraduated",
        inputs: [{ name: "student", type: "address" }],
        outputs: [{ name: "", type: "bool" }],
        stateMutability: "view",
    },
    {
        type: "function",
        name: "getGPA",
        inputs: [{ name: "student", type: "address" }],
        outputs: [{ name: "", type: "uint16" }],
        stateMutability: "view",
    },
    {
        type: "function",
        name: "owner",
        inputs: [],
        outputs: [{ name: "", type: "address" }],
        stateMutability: "view",
    },
    {
        type: "function",
        name: "getPendingApplicants",
        inputs: [],
        outputs: [{ name: "", type: "address[]" }],
        stateMutability: "view",
    },
    {
        type: "function",
        name: "listEnrolledStudents",
        inputs: [],
        outputs: [{ name: "", type: "address[]" }],
        stateMutability: "view",
    },
    {
        type: "function",
        name: "updateApplicationStatus",
        inputs: [
            { name: "applicant", type: "address" },
            { name: "majorName", type: "string" },
            { name: "status", type: "uint8" },
        ],
        outputs: [],
        stateMutability: "nonpayable",
    },
    {
        type: "function",
        name: "updateStudentGPA",
        inputs: [
            { name: "student", type: "address" },
            { name: "gpa", type: "uint16" },
        ],
        outputs: [],
        stateMutability: "nonpayable",
    },
    {
        type: "function",
        name: "graduateStudent",
        inputs: [{ name: "student", type: "address" }],
        outputs: [],
        stateMutability: "nonpayable",
    },
    {
        type: "event",
        name: "ApplicationSubmitted",
        inputs: [{ name: "applicant", type: "address", indexed: false }],
    },
    {
        type: "event",
        name: "StudentEnrolled",
        inputs: [
            { name: "studentId", type: "string", indexed: false },
            { name: "faculty", type: "string", indexed: false },
            { name: "major", type: "string", indexed: false },
            { name: "status", type: "uint8", indexed: false },
        ],
    },
] as const;

// FacultyAndMajor Contract ABI (key functions only)
export const facultyAndMajorAbi = [
    {
        type: "function",
        name: "listFaculties",
        inputs: [],
        outputs: [{ name: "", type: "string[]" }],
        stateMutability: "view",
    },
    {
        type: "function",
        name: "listMajors",
        inputs: [{ name: "facultyName", type: "string" }],
        outputs: [{ name: "", type: "string[]" }],
        stateMutability: "view",
    },
    {
        type: "function",
        name: "getMajorCost",
        inputs: [
            { name: "facultyName", type: "string" },
            { name: "majorName", type: "string" },
        ],
        outputs: [{ name: "", type: "uint256" }],
        stateMutability: "view",
    },
    {
        type: "function",
        name: "universityName",
        inputs: [],
        outputs: [{ name: "", type: "string" }],
        stateMutability: "view",
    },
] as const;

// Certificate Contract ABI
export const certificateAbi = [
    {
        type: "function",
        name: "mintCertificate",
        inputs: [],
        outputs: [],
        stateMutability: "nonpayable",
    },
    {
        type: "function",
        name: "hasClaimed",
        inputs: [{ name: "", type: "address" }],
        outputs: [{ name: "", type: "bool" }],
        stateMutability: "view",
    },
    {
        type: "event",
        name: "CertificateMinted",
        inputs: [
            { name: "student", type: "address", indexed: true },
            { name: "tokenId", type: "uint256", indexed: false },
        ],
    },
] as const;

// Deployed contract addresses (Sepolia Testnet)
export const contractAddresses = {
    students: "0x85B7e058d1eDaeBaF9b64fd1AE9F0c515230030E" as const,
    facultyAndMajor: "0xD75e722E3579148eC6C2B1306C7629C4Fe0eB737" as const,
    certificate: "0xFE1d94CCe73d50C6370ce3Bb61Da4648837b1e66" as const,
} as const;

