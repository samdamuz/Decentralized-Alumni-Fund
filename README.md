# 🎓 Decentralized Alumni Fund

A blockchain-powered platform where alumni pool resources to sponsor students, creating a sustainable cycle of educational support through repayments and gratitude tokens.

## 🌟 Features

- **👥 Alumni Pool**: Alumni contribute STX tokens to a shared fund
- **🎯 Student Funding**: Students create funding requests for educational needs  
- **🗳️ Democratic Voting**: Alumni vote on funding proposals
- **💰 Automatic Distribution**: Approved requests receive funding automatically
- **🔄 Repayment System**: Students can repay when able, strengthening the fund
- **🏆 Gratitude Tokens**: Earn reputation tokens for contributions and repayments
- **📊 Reputation System**: Track contributions and build community trust

## 🚀 Quick Start

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Stacks wallet with STX tokens

### Installation
```bash
git clone https://github.com/your-repo/Decentralized-Alumni-Fund
cd Decentralized-Alumni-Fund
clarinet check
```

## 📖 Usage Guide

### For Alumni 👨‍💼👩‍💼

1. **Register as Alumni**
   ```clarity
   (contract-call? .Decentralized-Alumni-Fund register-alumni)
   ```

2. **Contribute to Fund** 💎
   ```clarity
   (contract-call? .Decentralized-Alumni-Fund contribute-to-fund u1000) ;; 1000 microSTX
   ```

3. **Vote on Student Requests** 🗳️
   ```clarity
   (contract-call? .Decentralized-Alumni-Fund vote-on-request u1 "approve")
   ```

4. **Fund Approved Requests** ✅
   ```clarity
   (contract-call? .Decentralized-Alumni-Fund fund-approved-request u1)
   ```

### For Students 🎓

1. **Register as Student**
   ```clarity
   (contract-call? .Decentralized-Alumni-Fund register-student)
   ```

2. **Create Funding Request** 📝
   ```clarity
   (contract-call? .Decentralized-Alumni-Fund create-funding-request u5000 "Textbook and lab equipment for Computer Science")
   ```

3. **Repay When Possible** 🔄
   ```clarity
   (contract-call? .Decentralized-Alumni-Fund repay-funding u1 u1000)
   ```

4. **Send Gratitude** 💝
   ```clarity
   (contract-call? .Decentralized-Alumni-Fund send-gratitude 'ST1234... u50 "Thank you for supporting my education!")
   ```

## 🏗️ Contract Architecture

### Core Components

- **Alumni Management**: Registration and contribution tracking
- **Student Management**: Registration and funding history  
- **Funding Requests**: Democratic proposal and voting system
- **Repayment System**: Flexible repayment with reputation rewards
- **Gratitude Tokens**: Community appreciation and reputation building

### Key Functions

| Function | Description | Who Can Call |
|----------|-------------|--------------|
| `register-alumni` | Join as an alumni contributor | Anyone |
| `register-student` | Join as a student seeking funding | Anyone |
| `contribute-to-fund` | Add STX to the alumni fund | Registered alumni |
| `create-funding-request` | Request funding for education | Registered students |
| `vote-on-request` | Vote on student proposals | Registered alumni |
| `repay-funding` | Repay received funding | Funded students |
| `send-gratitude` | Send gratitude tokens | Token holders |

## 📊 Data Structures

### Alumni Profile
- Total contributed amount
- Reputation score  
- Join block height
- Activity status

### Student Profile  
- Total received funding
- Total repaid amount
- Reputation score
- Join block height

### Funding Request
- Student address
- Requested amount
- Purpose description
- Approval/rejection votes
- Funding status

## 🎯 Example Workflow

1. **🔗 Alumni Registration**: John registers and contributes 10,000 STX
2. **📚 Student Request**: Sarah requests 2,000 STX for coding bootcamp
3. **🗳️ Community Vote**: Alumni vote to approve Sarah's request  
4. **💰 Automatic Funding**: Sarah receives 2,000 STX when approved
5. **🔄 Grateful Repayment**: Sarah repays 2,500 STX after landing a job
6. **🏆 Reputation Growth**: Both John and Sarah earn gratitude tokens

## 🛡️ Security Features

- **Principal-based access control**
- **Overflow protection on all calculations**  
- **Vote tracking to prevent double-voting**
- **Emergency pause functionality**
- **Minimum contribution requirements**

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🌈 Community

Join our community of alumni and students building the future of decentralized education funding!

- **Discord**: [Join our server](https://discord.gg/alumni-fund)  
- **Twitter**: [@AlumniFundDAO](https://twitter.com/AlumniFundDAO)
- **Telegram**: [Alumni Fund Community](https://t.me/alumni-fund)

---

*Built with ❤️ for the education community*
