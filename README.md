# 🎓 University Registration System

A decentralized university registration system built with Solidity and Foundry, featuring Chainlink Automation for automated enrollment periods and ERC721 NFT certificates for graduates.

## ✨ Features

- **Faculty & Major Management** - Add, update, and manage faculties and majors with customizable codes
- **Student Enrollment** - Two-step enrollment process (apply → approve → pay)
- **Chainlink Automation** - Automated opening/closing of enrollment periods based on configured months
- **GPA Tracking** - Track student GPA (stored as uint16, e.g., 350 = 3.50)
- **Graduation System** - Graduate students who meet semester and GPA requirements
- **NFT Certificates** - ERC721 certificates for graduated students
- **Semester Calculation** - Automatic semester progression based on enrollment date

## 🏗️ Architecture

```
┌─────────────────────┐     ┌──────────────────┐     ┌────────────────────┐
│  FacultyAndMajor    │◄────│     Students     │────►│    Certificate     │
│  - Add faculties    │     │  - Enrollment    │     │   (ERC721 NFT)     │
│  - Add majors       │     │  - GPA tracking  │     │  - Mint on grad    │
│  - Student counts   │     │  - Graduation    │     └────────────────────┘
└─────────────────────┘     └──────────────────┘
                                    │
                                    ▼
                            ┌──────────────────┐
                            │ Chainlink        │
                            │ Automation       │
                            │ (checkUpkeep)    │
                            └──────────────────┘
```

## 📦 Contracts

| Contract | Description |
|----------|-------------|
| `FacultyAndMajor.sol` | Manages faculties, majors, and student counts |
| `Students.sol` | Handles enrollment, GPA, graduation, integrates Chainlink |
| `Certificate.sol` | ERC721 NFT for graduation certificates |
| `OwnerControlled.sol` | Base access control with withdraw functionality |
| `Check.sol` | Library for input validation |
| `Email.sol` | Library for generating student emails |

## 🚀 Getting Started

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Git

### Installation

```bash
git clone https://github.com/KamiliaNHayati/UniversityRegistration.git
cd UniversityRegistration
forge install
```

### Build

```bash
forge build
```

### Test

```bash
forge test
```

### Test Coverage

```bash
forge coverage
```

**Current Coverage: 97%+** ✅

## 📋 Usage

## 🌐 Deployed Contracts (Sepolia Testnet)

| Contract | Address |
|----------|---------|
| FacultyAndMajor | [`0x4862ff14b4e032f9aA68eEA8b21ee96655E33d9c`](https://sepolia.etherscan.io/address/0x4862ff14b4e032f9aA68eEA8b21ee96655E33d9c) |
| Students | [`0x73D1a473f32b82bD3019d028ee664B5cc9D2F5D1`](https://sepolia.etherscan.io/address/0x73D1a473f32b82bD3019d028ee664B5cc9D2F5D1) |
| Certificate | [`0xe0187e061DA32222C51c5093c801d835E169D2BA`](https://sepolia.etherscan.io/address/0xe0187e061DA32222C51c5093c801d835E169D2BA) |

### Deploy Contracts

```bash
# Deploy FacultyAndMajor
forge script script/FacultyAndMajor.s.sol --rpc-url <RPC_URL> --private-key <PRIVATE_KEY> --broadcast

# Deploy Students (requires FacultyAndMajor address)
forge script script/Students.s.sol --rpc-url <RPC_URL> --private-key <PRIVATE_KEY> --broadcast

# Deploy Certificate (requires Students address)
forge script script/Certificate.s.sol --rpc-url <RPC_URL> --private-key <PRIVATE_KEY> --broadcast
```

### Enrollment Flow

1. **Owner adds faculty and major**
   ```solidity
   facultyAndMajor.addFaculty("School of Computing", "1200");
   facultyAndMajor.addMajor("School of Computing", "Information Technology", "1201", 110, 0.8 ether);
   ```

2. **Student applies during enrollment period**
   ```solidity
   students.applyForEnrollment("John Doe", "School of Computing", "Information Technology");
   ```

3. **Owner approves application**
   ```solidity
   students.updateApplicationStatus(studentAddress, ApplicationStatus.Approved);
   ```

4. **Student pays and enrolls**
   ```solidity
   students.enrollStudent{value: 0.8 ether}();
   ```

5. **Owner updates GPA and graduates student**
   ```solidity
   students.updateStudentGPA(studentAddress, 350); // 3.50 GPA
   students.graduateStudent(studentAddress);
   ```

6. **Student mints certificate NFT**
   ```solidity
   certificate.mintCertificate();
   ```

## 🔧 Configuration

| Parameter | Description |
|-----------|-------------|
| `minimumMonth` | Start of enrollment period (e.g., 6 = June) |
| `maximumMonth` | End of enrollment period (e.g., 8 = August) |
| `validityEndMonth` | Validity period end month |
| `validityEndDay` | Validity period end day |
| `validityYearOffset` | Years to add for validity |

## 🧪 Test Structure

```
test/
├── core/
│   ├── FacultyAndMajor.t.sol
│   ├── Students.t.sol
│   └── Certificate.t.sol
└── libraries/
    ├── Check.t.sol
    └── Email.t.sol
```

## 🛠️ Technologies

- **Solidity** ^0.8.20
- **Foundry** - Development framework
- **OpenZeppelin** - ERC721, Ownable
- **Chainlink** - Automation Compatible Interface
- **BokkyPooBahs DateTime** - Date/time calculations

## 📄 License

MIT

## 👤 Author

**Kamilia N Hayati**

- GitHub: [@KamiliaNHayati](https://github.com/KamiliaNHayati)
