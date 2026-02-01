'use client';

import { ConnectButton } from '@rainbow-me/rainbowkit';
import { useAccount, useReadContract, useWriteContract, useWaitForTransactionReceipt } from 'wagmi';
import { studentsAbi, facultyAndMajorAbi, contractAddresses } from '@/contracts';
import { useState } from 'react';
import Link from 'next/link';

type TabType = 'applications' | 'students' | 'gpa' | 'graduate';

export default function Admin() {
    const { address, isConnected } = useAccount();
    const [activeTab, setActiveTab] = useState<TabType>('applications');
    const [selectedApplicant, setSelectedApplicant] = useState<string>('');
    const [gpaStudent, setGpaStudent] = useState<string>('');
    const [gpaValue, setGpaValue] = useState<string>('');
    const [graduateStudent, setGraduateStudent] = useState<string>('');

    // Check if user is admin
    const { data: owner } = useReadContract({
        address: contractAddresses.students,
        abi: studentsAbi,
        functionName: 'owner',
    });

    const isAdmin = address && owner && address.toLowerCase() === owner.toLowerCase();

    // Read university name
    const { data: universityName } = useReadContract({
        address: contractAddresses.facultyAndMajor,
        abi: facultyAndMajorAbi,
        functionName: 'universityName',
    });

    // Get pending applicants
    const { data: pendingApplicants } = useReadContract({
        address: contractAddresses.students,
        abi: studentsAbi,
        functionName: 'getPendingApplicants',
    });

    // Get enrolled students
    const { data: enrolledStudents } = useReadContract({
        address: contractAddresses.students,
        abi: studentsAbi,
        functionName: 'listEnrolledStudents',
    });

    // Write contracts
    const { writeContract: updateStatus, data: statusHash, isPending: statusPending, error: statusError } = useWriteContract();
    const { isLoading: statusConfirming, isSuccess: statusSuccess } = useWaitForTransactionReceipt({ hash: statusHash });

    const { writeContract: updateGPA, data: gpaHash, isPending: gpaPending, error: gpaError } = useWriteContract();
    const { isLoading: gpaConfirming, isSuccess: gpaSuccess } = useWaitForTransactionReceipt({ hash: gpaHash });

    const { writeContract: graduate, data: gradHash, isPending: gradPending, error: gradError } = useWriteContract();
    const { isLoading: gradConfirming, isSuccess: gradSuccess } = useWaitForTransactionReceipt({ hash: gradHash });

    const handleApprove = (applicantAddress: string, major: string) => {
        updateStatus({
            address: contractAddresses.students,
            abi: studentsAbi,
            functionName: 'updateApplicationStatus',
            args: [applicantAddress as `0x${string}`, major, 1],
        });
        setSelectedApplicant(applicantAddress);
    };

    const handleReject = (applicantAddress: string, major: string) => {
        updateStatus({
            address: contractAddresses.students,
            abi: studentsAbi,
            functionName: 'updateApplicationStatus',
            args: [applicantAddress as `0x${string}`, major, 2],
        });
        setSelectedApplicant(applicantAddress);
    };

    const handleUpdateGPA = () => {
        if (!gpaStudent || !gpaValue) return;
        const gpaInt = Math.round(parseFloat(gpaValue) * 100);
        updateGPA({
            address: contractAddresses.students,
            abi: studentsAbi,
            functionName: 'updateStudentGPA',
            args: [gpaStudent as `0x${string}`, gpaInt],
        });
    };

    const handleGraduate = () => {
        if (!graduateStudent) return;
        graduate({
            address: contractAddresses.students,
            abi: studentsAbi,
            functionName: 'graduateStudent',
            args: [graduateStudent as `0x${string}`],
        });
    };

    const tabs = [
        { id: 'applications' as TabType, label: 'Applications', icon: '📝', count: pendingApplicants?.length || 0 },
        { id: 'students' as TabType, label: 'Students', icon: '👥', count: enrolledStudents?.length || 0 },
        { id: 'gpa' as TabType, label: 'Update GPA', icon: '📊', count: null },
        { id: 'graduate' as TabType, label: 'Graduate', icon: '🎓', count: null },
    ];

    if (!isConnected) {
        return (
            <main className="min-h-screen animated-bg relative overflow-hidden flex items-center justify-center">
                <div className="orb orb-purple" />
                <div className="orb orb-pink" />
                <div className="text-center animate-fade-in">
                    <div className="w-24 h-24 mx-auto mb-8 rounded-full bg-purple-500/20 flex items-center justify-center text-5xl">🔐</div>
                    <h2 className="text-4xl font-bold text-white mb-4" style={{ fontFamily: 'Space Grotesk' }}>Admin Panel</h2>
                    <p className="text-gray-400 mb-8">Connect your admin wallet to continue</p>
                    <div className="flex justify-center">
                        <ConnectButton />
                    </div>
                </div>
            </main>
        );
    }

    if (!isAdmin) {
        return (
            <main className="min-h-screen animated-bg relative overflow-hidden flex items-center justify-center">
                <div className="orb orb-purple" />
                <div className="orb orb-pink" />
                <div className="text-center animate-fade-in">
                    <div className="w-24 h-24 mx-auto mb-8 rounded-full bg-red-500/20 flex items-center justify-center text-5xl">⛔</div>
                    <h2 className="text-4xl font-bold text-red-400 mb-4" style={{ fontFamily: 'Space Grotesk' }}>Access Denied</h2>
                    <p className="text-gray-400 mb-8">Only the contract owner can access this page.</p>
                    <Link href="/" className="text-purple-400 hover:text-purple-300 transition">← Back to Home</Link>
                </div>
            </main>
        );
    }

    return (
        <main className="min-h-screen animated-bg relative overflow-hidden">
            {/* Decorative Orbs */}
            <div className="orb orb-purple" />
            <div className="orb orb-pink" />

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
                            <Link href="/" className="text-gray-400 hover:text-white transition">Apply</Link>
                            <Link href="/dashboard" className="text-gray-400 hover:text-white transition">Dashboard</Link>
                            <Link href="/admin" className="text-purple-400 font-medium">Admin</Link>
                        </nav>
                    </div>
                    <ConnectButton />
                </div>
            </header>

            {/* Main Content */}
            <div className="relative z-10 max-w-6xl mx-auto px-6 py-10">
                <div className="flex items-center gap-4 mb-8 animate-fade-in">
                    <div className="w-14 h-14 rounded-xl bg-purple-500/20 flex items-center justify-center text-3xl">🛠️</div>
                    <div>
                        <h2 className="text-3xl font-bold text-white" style={{ fontFamily: 'Space Grotesk' }}>Admin Panel</h2>
                        <p className="text-gray-400">Manage applications, students, and academic records</p>
                    </div>
                </div>

                {/* Stats Overview */}
                <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-8 animate-fade-in">
                    <div className="stat-card">
                        <div className="stat-value">{pendingApplicants?.length || 0}</div>
                        <div className="stat-label">Pending</div>
                    </div>
                    <div className="stat-card">
                        <div className="stat-value">{enrolledStudents?.length || 0}</div>
                        <div className="stat-label">Enrolled</div>
                    </div>
                    <div className="stat-card">
                        <div className="stat-value">-</div>
                        <div className="stat-label">Graduated</div>
                    </div>
                    <div className="stat-card">
                        <div className="stat-value">-</div>
                        <div className="stat-label">Total Apps</div>
                    </div>
                </div>

                {/* Tabs */}
                <div className="flex gap-2 mb-6 flex-wrap animate-fade-in">
                    {tabs.map((tab) => (
                        <button
                            key={tab.id}
                            onClick={() => setActiveTab(tab.id)}
                            className={`px-5 py-3 rounded-xl font-medium transition flex items-center gap-2 ${activeTab === tab.id
                                ? 'bg-purple-500 text-white glow-purple'
                                : 'bg-white/5 text-gray-400 hover:bg-white/10 border border-white/10'
                                }`}
                        >
                            <span>{tab.icon}</span>
                            <span>{tab.label}</span>
                            {tab.count !== null && (
                                <span className={`px-2 py-0.5 rounded-full text-xs ${activeTab === tab.id ? 'bg-white/20' : 'bg-purple-500/30 text-purple-400'}`}>
                                    {tab.count}
                                </span>
                            )}
                        </button>
                    ))}
                </div>

                {/* Tab Content */}
                <div className="glass-card p-8 animate-fade-in">
                    {/* Applications Tab */}
                    {activeTab === 'applications' && (
                        <div>
                            <h3 className="text-xl font-semibold text-white mb-6" style={{ fontFamily: 'Space Grotesk' }}>Pending Applications</h3>
                            {pendingApplicants && pendingApplicants.length > 0 ? (
                                <div className="space-y-4">
                                    {pendingApplicants.map((applicant, index) => (
                                        <ApplicationCard
                                            key={index}
                                            address={applicant}
                                            onApprove={handleApprove}
                                            onReject={handleReject}
                                            isPending={statusPending || statusConfirming}
                                            isSelected={selectedApplicant === applicant}
                                        />
                                    ))}
                                </div>
                            ) : (
                                <div className="text-center py-12">
                                    <div className="text-5xl mb-4">📭</div>
                                    <p className="text-gray-400">No pending applications at the moment.</p>
                                </div>
                            )}
                            {statusSuccess && (
                                <div className="mt-6 p-4 rounded-xl bg-green-500/10 border border-green-500/30 text-green-400 flex items-center gap-3">
                                    <span>✅</span> Application status updated successfully!
                                </div>
                            )}
                            {statusError && (
                                <div className="mt-6 p-4 rounded-xl bg-red-500/10 border border-red-500/30 text-red-400 flex items-center gap-3">
                                    <span>❌</span> {statusError.message.includes('AlreadyApproved') ? 'Application already approved' : 'Transaction failed'}
                                </div>
                            )}
                        </div>
                    )}

                    {/* Students Tab */}
                    {activeTab === 'students' && (
                        <div>
                            <h3 className="text-xl font-semibold text-white mb-6" style={{ fontFamily: 'Space Grotesk' }}>Enrolled Students</h3>
                            {enrolledStudents && enrolledStudents.length > 0 ? (
                                <div className="space-y-3">
                                    {enrolledStudents.map((student, index) => (
                                        <div key={index} className="p-4 rounded-xl bg-white/5 border border-white/10 flex justify-between items-center hover:border-purple-500/30 transition">
                                            <div className="flex items-center gap-4">
                                                <div className="w-10 h-10 rounded-full bg-purple-500/20 flex items-center justify-center text-lg">👤</div>
                                                <span className="text-white font-mono">{student}</span>
                                            </div>
                                            <span className="text-gray-400 text-sm">#{index + 1}</span>
                                        </div>
                                    ))}
                                </div>
                            ) : (
                                <div className="text-center py-12">
                                    <div className="text-5xl mb-4">👥</div>
                                    <p className="text-gray-400">No enrolled students yet.</p>
                                </div>
                            )}
                        </div>
                    )}

                    {/* Update GPA Tab */}
                    {activeTab === 'gpa' && (
                        <div>
                            <h3 className="text-xl font-semibold text-white mb-6" style={{ fontFamily: 'Space Grotesk' }}>Update Student GPA</h3>
                            <div className="space-y-5 max-w-lg">
                                <div>
                                    <label className="block text-gray-300 text-sm font-medium mb-3">Student Address</label>
                                    <input
                                        type="text"
                                        value={gpaStudent}
                                        onChange={(e) => setGpaStudent(e.target.value)}
                                        placeholder="0x..."
                                        className="w-full px-5 py-4 input-glass rounded-xl text-white font-mono"
                                    />
                                </div>
                                <div>
                                    <label className="block text-gray-300 text-sm font-medium mb-3">GPA (0.00 - 4.00)</label>
                                    <input
                                        type="number"
                                        step="0.01"
                                        min="0"
                                        max="4"
                                        value={gpaValue}
                                        onChange={(e) => setGpaValue(e.target.value)}
                                        placeholder="3.50"
                                        className="w-full px-5 py-4 input-glass rounded-xl text-white text-2xl font-semibold"
                                    />
                                </div>
                                <button
                                    onClick={handleUpdateGPA}
                                    disabled={gpaPending || gpaConfirming || !gpaStudent || !gpaValue}
                                    className="px-8 py-4 btn-primary text-white font-semibold rounded-xl"
                                >
                                    {gpaPending ? '⏳ Confirming...' : gpaConfirming ? '⛓️ Processing...' : '📊 Update GPA'}
                                </button>
                                {gpaSuccess && (
                                    <div className="p-4 rounded-xl bg-green-500/10 border border-green-500/30 text-green-400 flex items-center gap-3">
                                        <span>✅</span> GPA updated successfully!
                                    </div>
                                )}
                                {gpaError && (
                                    <div className="p-4 rounded-xl bg-red-500/10 border border-red-500/30 text-red-400 flex items-center gap-3">
                                        <span>❌</span> Error updating GPA
                                    </div>
                                )}
                            </div>
                        </div>
                    )}

                    {/* Graduate Tab */}
                    {activeTab === 'graduate' && (
                        <div>
                            <h3 className="text-xl font-semibold text-white mb-2" style={{ fontFamily: 'Space Grotesk' }}>Graduate Student</h3>
                            <p className="text-gray-400 mb-6">Requirements: Semester ≥ 7, GPA ≥ 2.00</p>
                            <div className="space-y-5 max-w-lg">
                                <div>
                                    <label className="block text-gray-300 text-sm font-medium mb-3">Student Address</label>
                                    <input
                                        type="text"
                                        value={graduateStudent}
                                        onChange={(e) => setGraduateStudent(e.target.value)}
                                        placeholder="0x..."
                                        className="w-full px-5 py-4 input-glass rounded-xl text-white font-mono"
                                    />
                                </div>
                                <button
                                    onClick={handleGraduate}
                                    disabled={gradPending || gradConfirming || !graduateStudent}
                                    className="px-8 py-4 btn-primary text-white font-semibold rounded-xl"
                                >
                                    {gradPending ? '⏳ Confirming...' : gradConfirming ? '⛓️ Processing...' : '🎓 Graduate Student'}
                                </button>
                                {gradSuccess && (
                                    <div className="p-4 rounded-xl bg-green-500/10 border border-green-500/30 text-green-400 flex items-center gap-3">
                                        <span>✅</span> Student graduated successfully!
                                    </div>
                                )}
                                {gradError && (
                                    <div className="p-4 rounded-xl bg-red-500/10 border border-red-500/30 text-red-400 flex items-center gap-3">
                                        <span>❌</span> {gradError.message.includes('NotEligible') ? 'Student not eligible (semester < 7)' :
                                            gradError.message.includes('GPATooLow') ? 'GPA too low (< 2.00)' : 'Transaction failed'}
                                    </div>
                                )}
                            </div>
                        </div>
                    )}
                </div>
            </div>

            {/* Footer */}
            <footer className="relative z-10 border-t border-white/10 mt-20">
                <div className="max-w-7xl mx-auto px-6 py-8 text-center text-gray-500 text-sm">
                    <p>© 2026 {universityName || 'UniReg'} • Built with 💜 on Ethereum</p>
                </div>
            </footer>
        </main>
    );
}

// Application Card Component
function ApplicationCard({
    address,
    onApprove,
    onReject,
    isPending,
    isSelected
}: {
    address: string;
    onApprove: (address: string, major: string) => void;
    onReject: (address: string, major: string) => void;
    isPending: boolean;
    isSelected: boolean;
}) {
    const { data: application } = useReadContract({
        address: contractAddresses.students,
        abi: studentsAbi,
        functionName: 'applications',
        args: [address as `0x${string}`, BigInt(0)],
    });

    if (!application) return null;

    return (
        <div className="p-5 rounded-xl bg-white/5 border border-white/10 hover:border-purple-500/30 transition">
            <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
                <div className="flex-1">
                    <div className="flex items-center gap-3 mb-2">
                        <div className="w-10 h-10 rounded-full bg-purple-500/20 flex items-center justify-center">👤</div>
                        <div>
                            <p className="text-white font-semibold">{application[1]}</p>
                            <p className="text-gray-500 text-xs font-mono">{address.slice(0, 10)}...{address.slice(-8)}</p>
                        </div>
                    </div>
                    <div className="flex gap-4 mt-3">
                        <span className="text-sm text-gray-400">Faculty: <span className="text-purple-400">{application[2]}</span></span>
                        <span className="text-sm text-gray-400">Major: <span className="text-white">{application[3]}</span></span>
                    </div>
                </div>
                <div className="flex gap-3">
                    <button
                        onClick={() => onApprove(address, application[3])}
                        disabled={isPending && isSelected}
                        className="px-5 py-2.5 rounded-lg bg-green-500/20 text-green-400 font-medium hover:bg-green-500/30 border border-green-500/30 transition disabled:opacity-50"
                    >
                        ✅ Approve
                    </button>
                    <button
                        onClick={() => onReject(address, application[3])}
                        disabled={isPending && isSelected}
                        className="px-5 py-2.5 rounded-lg bg-red-500/20 text-red-400 font-medium hover:bg-red-500/30 border border-red-500/30 transition disabled:opacity-50"
                    >
                        ❌ Reject
                    </button>
                </div>
            </div>
        </div>
    );
}
