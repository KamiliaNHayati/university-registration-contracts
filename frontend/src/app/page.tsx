'use client';

import { ConnectButton } from '@rainbow-me/rainbowkit';
import { useAccount, useReadContract, useWriteContract, useWaitForTransactionReceipt } from 'wagmi';
import { studentsAbi, facultyAndMajorAbi, contractAddresses } from '@/contracts';
import { useState, useEffect } from 'react';
import Link from 'next/link';

export default function Home() {
  const { address, isConnected } = useAccount();
  const [formData, setFormData] = useState({
    name: '',
    faculty: '',
    major: '',
  });
  const [error, setError] = useState<string | null>(null);

  // Check if user is admin
  const { data: owner } = useReadContract({
    address: contractAddresses.students,
    abi: studentsAbi,
    functionName: 'owner',
  });

  const isAdmin = address && owner && address.toLowerCase() === owner.toLowerCase();

  // Read enrollment status
  const { data: isOpen } = useReadContract({
    address: contractAddresses.students,
    abi: studentsAbi,
    functionName: 'isOpen',
  });

  // Read application status (first application at index 0)
  const { data: application } = useReadContract({
    address: contractAddresses.students,
    abi: studentsAbi,
    functionName: 'applications',
    args: address ? [address, BigInt(0)] : undefined,
    query: { enabled: !!address },
  });

  // Read faculties list from FacultyAndMajor contract
  const { data: faculties } = useReadContract({
    address: contractAddresses.facultyAndMajor,
    abi: facultyAndMajorAbi,
    functionName: 'listFaculties',
  });

  // Read university name
  const { data: universityName } = useReadContract({
    address: contractAddresses.facultyAndMajor,
    abi: facultyAndMajorAbi,
    functionName: 'universityName',
  });

  // Read majors for selected faculty
  const { data: majors } = useReadContract({
    address: contractAddresses.facultyAndMajor,
    abi: facultyAndMajorAbi,
    functionName: 'listMajors',
    args: formData.faculty ? [formData.faculty] : undefined,
    query: { enabled: !!formData.faculty },
  });

  // Reset major when faculty changes
  useEffect(() => {
    setFormData(prev => ({ ...prev, major: '' }));
  }, [formData.faculty]);

  // Write contract hooks
  const { writeContract, data: hash, isPending, error: writeError } = useWriteContract();

  const { isLoading: isConfirming, isSuccess, error: txError } = useWaitForTransactionReceipt({
    hash,
  });

  // Handle errors
  useEffect(() => {
    if (writeError) {
      const errorMessage = parseError(writeError);
      setError(errorMessage);
    } else if (txError) {
      setError('Transaction failed. Please try again.');
    } else {
      setError(null);
    }
  }, [writeError, txError]);

  // Clear error on success
  useEffect(() => {
    if (isSuccess) {
      setError(null);
    }
  }, [isSuccess]);

  const handleApply = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    if (!formData.name || !formData.faculty || !formData.major) return;

    writeContract({
      address: contractAddresses.students,
      abi: studentsAbi,
      functionName: 'applyForEnrollment',
      args: [formData.name, formData.faculty, formData.major],
    });
  };

  return (
    <main className="min-h-screen animated-bg relative overflow-hidden">
      {/* Decorative Orbs */}
      <div className="orb orb-purple" />
      <div className="orb orb-pink" />
      <div className="orb orb-blue" />

      {/* Header */}
      <header className="relative z-10 border-b border-white/10 backdrop-blur-md">
        <div className="max-w-7xl mx-auto px-6 py-5 flex justify-between items-center">
          <div className="flex items-center gap-8">
            <Link href="/" className="flex items-center gap-2">
              <span className="text-3xl">🎓</span>
              <span className="text-2xl font-bold gradient-text" style={{ fontFamily: 'Space Grotesk' }}>
                {universityName || 'UniReg'}
              </span>
            </Link>
            <nav className="hidden md:flex gap-6">
              <Link href="/" className="text-white font-medium hover:text-purple-400 transition">Apply</Link>
              <Link href="/dashboard" className="text-gray-400 hover:text-white transition">Dashboard</Link>
              {isAdmin && <Link href="/admin" className="text-purple-400 hover:text-purple-300 transition font-medium">Admin</Link>}
            </nav>
          </div>
          <ConnectButton />
        </div>
      </header>

      {/* Main Content */}
      <div className="relative z-10 max-w-5xl mx-auto px-6 py-16">
        {!isConnected ? (
          <div className="text-center py-16 animate-fade-in">
            <div className="inline-block mb-6 px-4 py-2 rounded-full bg-purple-500/10 border border-purple-500/30 text-purple-400 text-sm font-medium">
              ⚡ {universityName || 'Decentralized University'} Registration
            </div>
            <h1 className="hero-title gradient-text mb-6">
              Your Future<br />Starts Here
            </h1>
            <p className="text-gray-400 text-xl max-w-2xl mx-auto mb-10 leading-relaxed">
              Join the blockchain revolution in education. Apply for enrollment with full transparency and security powered by Ethereum.
            </p>
            <div className="flex justify-center gap-4">
              <ConnectButton />
            </div>

            {/* Feature Cards */}
            <div className="grid md:grid-cols-3 gap-6 mt-20">
              {[
                { icon: '🔒', title: 'Secure', desc: 'Blockchain-verified credentials' },
                { icon: '⚡', title: 'Fast', desc: 'Instant application processing' },
                { icon: '🌐', title: 'Transparent', desc: 'All records on-chain' },
              ].map((feature) => (
                <div key={feature.title} className="glass-card p-6 text-center">
                  <div className="text-4xl mb-4">{feature.icon}</div>
                  <h3 className="text-white font-semibold text-lg mb-2">{feature.title}</h3>
                  <p className="text-gray-400 text-sm">{feature.desc}</p>
                </div>
              ))}
            </div>
          </div>
        ) : (
          <div className="space-y-8 animate-fade-in">
            {/* Status Cards */}
            <div className="grid md:grid-cols-2 gap-6">
              <div className="stat-card">
                <div className="text-gray-400 text-sm uppercase tracking-wider mb-2">Enrollment Status</div>
                <div className={`stat-value ${isOpen ? 'text-green-400' : 'text-red-400'}`} style={{ WebkitTextFillColor: isOpen ? '#22c55e' : '#ef4444' }}>
                  {isOpen ? 'OPEN' : 'CLOSED'}
                </div>
              </div>
              <div className="stat-card">
                <div className="text-gray-400 text-sm uppercase tracking-wider mb-2">Your Application</div>
                <div className="stat-value" style={{ fontSize: '1.5rem' }}>
                  {application && application[0] !== '0x0000000000000000000000000000000000000000'
                    ? (
                      <span className={`badge ${getStatusClass(Number(application[4]))}`}>
                        {getStatusText(Number(application[4]))}
                      </span>
                    )
                    : <span className="text-gray-500">Not Applied</span>}
                </div>
              </div>
            </div>

            {/* Application Form */}
            <div className="glass-card p-8">
              <div className="flex items-center gap-3 mb-8">
                <div className="w-12 h-12 rounded-xl bg-purple-500/20 flex items-center justify-center text-2xl">📝</div>
                <div>
                  <h2 className="text-2xl font-bold text-white" style={{ fontFamily: 'Space Grotesk' }}>Apply for Enrollment</h2>
                  <p className="text-gray-400 text-sm">Fill in your details to submit an application</p>
                </div>
              </div>

              <form onSubmit={handleApply} className="space-y-6">
                <div>
                  <label className="block text-gray-300 text-sm font-medium mb-3">Full Name</label>
                  <input
                    type="text"
                    value={formData.name}
                    onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                    className="w-full px-5 py-4 input-glass rounded-xl text-white text-lg"
                    placeholder="Enter your full name"
                  />
                </div>

                <div className="grid md:grid-cols-2 gap-6">
                  <div>
                    <label className="block text-gray-300 text-sm font-medium mb-3">Faculty</label>
                    <select
                      value={formData.faculty}
                      onChange={(e) => setFormData({ ...formData, faculty: e.target.value })}
                      className="w-full px-5 py-4 input-glass rounded-xl text-white cursor-pointer appearance-none"
                      style={{ backgroundImage: 'url("data:image/svg+xml,%3Csvg xmlns=\'http://www.w3.org/2000/svg\' fill=\'none\' viewBox=\'0 0 24 24\' stroke=\'%239ca3af\'%3E%3Cpath stroke-linecap=\'round\' stroke-linejoin=\'round\' stroke-width=\'2\' d=\'M19 9l-7 7-7-7\'%3E%3C/path%3E%3C/svg%3E")', backgroundRepeat: 'no-repeat', backgroundPosition: 'right 1rem center', backgroundSize: '1.5rem' }}
                    >
                      <option value="" className="bg-slate-900">Select Faculty</option>
                      {faculties?.map((faculty) => (
                        <option key={faculty} value={faculty} className="bg-slate-900">{faculty}</option>
                      ))}
                    </select>
                  </div>
                  <div>
                    <label className="block text-gray-300 text-sm font-medium mb-3">Major</label>
                    <select
                      value={formData.major}
                      onChange={(e) => setFormData({ ...formData, major: e.target.value })}
                      disabled={!formData.faculty}
                      className="w-full px-5 py-4 input-glass rounded-xl text-white cursor-pointer appearance-none disabled:opacity-50 disabled:cursor-not-allowed"
                      style={{ backgroundImage: 'url("data:image/svg+xml,%3Csvg xmlns=\'http://www.w3.org/2000/svg\' fill=\'none\' viewBox=\'0 0 24 24\' stroke=\'%239ca3af\'%3E%3Cpath stroke-linecap=\'round\' stroke-linejoin=\'round\' stroke-width=\'2\' d=\'M19 9l-7 7-7-7\'%3E%3C/path%3E%3C/svg%3E")', backgroundRepeat: 'no-repeat', backgroundPosition: 'right 1rem center', backgroundSize: '1.5rem' }}
                    >
                      <option value="" className="bg-slate-900">
                        {formData.faculty ? 'Select Major' : 'Select Faculty First'}
                      </option>
                      {majors?.map((major) => (
                        <option key={major} value={major} className="bg-slate-900">{major}</option>
                      ))}
                    </select>
                  </div>
                </div>

                <button
                  type="submit"
                  disabled={isPending || isConfirming || !isOpen || !formData.name || !formData.faculty || !formData.major}
                  className="w-full py-4 btn-primary text-white font-semibold rounded-xl text-lg"
                >
                  {isPending ? '⏳ Confirming in Wallet...' : isConfirming ? '⛓️ Processing on Chain...' : '🚀 Submit Application'}
                </button>

                {/* Error Message */}
                {error && (
                  <div className="p-4 rounded-xl bg-red-500/10 border border-red-500/30 text-red-400 flex items-center gap-3">
                    <span className="text-xl">❌</span>
                    <span>{error}</span>
                  </div>
                )}

                {/* Success Message */}
                {isSuccess && (
                  <div className="p-4 rounded-xl bg-green-500/10 border border-green-500/30 text-green-400 flex items-center gap-3">
                    <span className="text-xl">✅</span>
                    <span>Application submitted successfully! Check your dashboard for status updates.</span>
                  </div>
                )}
              </form>
            </div>

            {/* Network Info */}
            <div className="text-center text-gray-500 text-sm">
              <p>Connected to <span className="text-purple-400">Sepolia Testnet</span> • Contract: <span className="font-mono">{contractAddresses.students.slice(0, 10)}...</span></p>
            </div>
          </div>
        )}
      </div>

      {/* Footer */}
      <footer className="relative z-10 border-t border-white/10 mt-20">
        <div className="max-w-7xl mx-auto px-6 py-8">
          <div className="flex flex-col md:flex-row justify-between items-center gap-4">
            <p className="text-gray-500 text-sm">© 2026 {universityName || 'UniReg'} • Built with 💜 on Ethereum</p>
            <div className="flex gap-6">
              <a
                href={`https://sepolia.etherscan.io/address/${contractAddresses.students}`}
                target="_blank"
                rel="noopener noreferrer"
                className="text-gray-500 hover:text-purple-400 text-sm transition flex items-center gap-1"
              >
                📜 View on Etherscan
              </a>
              <a
                href="https://github.com/KamiliaNHayati/university-registration-contracts"
                target="_blank"
                rel="noopener noreferrer"
                className="text-gray-500 hover:text-purple-400 text-sm transition flex items-center gap-1"
              >
                ⭐ GitHub
              </a>
            </div>
          </div>
        </div>
      </footer>
    </main>
  );
}

function getStatusText(status: number): string {
  switch (status) {
    case 0: return '⏳ Pending';
    case 1: return '✅ Approved';
    case 2: return '❌ Rejected';
    case 3: return '🎓 Enrolled';
    default: return 'Unknown';
  }
}

function getStatusClass(status: number): string {
  switch (status) {
    case 0: return 'badge-pending';
    case 1: return 'badge-approved';
    case 2: return 'badge-rejected';
    case 3: return 'badge-enrolled';
    default: return '';
  }
}

function parseError(error: Error): string {
  const message = error.message || '';

  if (message.includes('NonOnlyOwner')) {
    return 'Contract owner cannot apply for enrollment. Please use a different wallet.';
  }
  if (message.includes('EnrollmentClosed')) {
    return 'Enrollment is currently closed.';
  }
  if (message.includes('AlreadyEnrolled')) {
    return 'You have already enrolled.';
  }
  if (message.includes('AlreadyApplied')) {
    return 'You have already applied for this major.';
  }
  if (message.includes('User rejected') || message.includes('user rejected')) {
    return 'Transaction was rejected in wallet.';
  }
  if (message.includes('insufficient funds')) {
    return 'Insufficient funds for gas fees.';
  }
  if (message.includes('gas') || message.includes('execution reverted') || message.includes('EstimateGasExecutionError')) {
    return 'Contract owner cannot apply for enrollment. Please use a different wallet.';
  }

  return 'Transaction failed. Please try again.';
}
