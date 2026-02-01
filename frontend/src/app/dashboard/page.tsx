'use client';

import { ConnectButton } from '@rainbow-me/rainbowkit';
import { useAccount, useReadContract, useWriteContract, useWaitForTransactionReceipt, useSimulateContract } from 'wagmi';
import { studentsAbi, facultyAndMajorAbi, certificateAbi, contractAddresses } from '@/contracts';
import { formatEther } from 'viem';
import Link from 'next/link';

export default function Dashboard() {
    const { address, isConnected } = useAccount();

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

    // Simulate getStudent call to get data without modifying state
    const { data: studentSimulation } = useSimulateContract({
        address: contractAddresses.students,
        abi: studentsAbi,
        functionName: 'getStudent',
        account: address,
        query: { enabled: !!address },
    });

    const studentData = studentSimulation?.result as readonly [string, string, string, string, string, number, number, string] | undefined;

    // Get first application (index 0)
    const { data: application } = useReadContract({
        address: contractAddresses.students,
        abi: studentsAbi,
        functionName: 'applications',
        args: address ? [address, BigInt(0)] : undefined,
        query: { enabled: !!address },
    });

    // Get GPA
    const { data: gpa } = useReadContract({
        address: contractAddresses.students,
        abi: studentsAbi,
        functionName: 'getGPA',
        args: address ? [address] : undefined,
        query: { enabled: !!address },
    });

    // Has graduated
    const { data: hasGraduated } = useReadContract({
        address: contractAddresses.students,
        abi: studentsAbi,
        functionName: 'hasGraduated',
        args: address ? [address] : undefined,
        query: { enabled: !!address },
    });

    // Has claimed certificate
    const { data: hasClaimed } = useReadContract({
        address: contractAddresses.certificate,
        abi: certificateAbi,
        functionName: 'hasClaimed',
        args: address ? [address] : undefined,
        query: { enabled: !!address },
    });

    // Get enrollment cost for payment
    const { data: enrollmentCost } = useReadContract({
        address: contractAddresses.facultyAndMajor,
        abi: facultyAndMajorAbi,
        functionName: 'getMajorCost',
        args: application ? [application[2], application[3]] : undefined,
        query: { enabled: !!application && application[0] !== '0x0000000000000000000000000000000000000000' },
    });

    // Write contract for enrollment
    const { writeContract: enroll, data: enrollHash, isPending: enrollPending } = useWriteContract();
    const { isLoading: enrollConfirming, isSuccess: enrollSuccess } = useWaitForTransactionReceipt({ hash: enrollHash });

    // Write contract for claim certificate
    const { writeContract: claimCert, data: claimHash, isPending: claimPending } = useWriteContract();
    const { isLoading: claimConfirming, isSuccess: claimSuccess } = useWaitForTransactionReceipt({ hash: claimHash });

    const handleEnroll = () => {
        if (!enrollmentCost) return;
        enroll({
            address: contractAddresses.students,
            abi: studentsAbi,
            functionName: 'enrollStudent',
            value: enrollmentCost,
        });
    };

    const handleClaimCertificate = () => {
        claimCert({
            address: contractAddresses.certificate,
            abi: certificateAbi,
            functionName: 'mintCertificate',
        });
    };

    const getStatusBadge = (status: number) => {
        switch (status) {
            case 0: return { text: 'Pending', class: 'badge-pending' };
            case 1: return { text: 'Approved', class: 'badge-approved' };
            case 2: return { text: 'Rejected', class: 'badge-rejected' };
            case 3: return { text: 'Enrolled', class: 'badge-enrolled' };
            default: return { text: 'Unknown', class: '' };
        }
    };

    const getStudentStatusText = (status: number) => {
        switch (status) {
            case 0: return { text: 'Active', color: 'text-green-400', icon: '🟢' };
            case 1: return { text: 'Graduated', color: 'text-purple-400', icon: '🎓' };
            case 2: return { text: 'Dropped Out', color: 'text-red-400', icon: '🔴' };
            default: return { text: 'Unknown', color: 'text-gray-400', icon: '⚪' };
        }
    };

    const hasEnrolled = studentData && studentData[0] !== '';
    const applicationStatus = application ? Number(application[4]) : -1;
    const isApproved = applicationStatus === 1;

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
                            <Link href="/dashboard" className="text-white font-medium">Dashboard</Link>
                            {isAdmin && <Link href="/admin" className="text-purple-400 hover:text-purple-300 transition font-medium">Admin</Link>}
                        </nav>
                    </div>
                    <ConnectButton />
                </div>
            </header>

            {/* Main Content */}
            <div className="relative z-10 max-w-5xl mx-auto px-6 py-12">
                {!isConnected ? (
                    <div className="text-center py-20 animate-fade-in">
                        <div className="w-24 h-24 mx-auto mb-8 rounded-full bg-purple-500/20 flex items-center justify-center text-5xl">📊</div>
                        <h2 className="text-4xl font-bold text-white mb-4" style={{ fontFamily: 'Space Grotesk' }}>Student Dashboard</h2>
                        <p className="text-gray-400 text-lg mb-8">Connect your wallet to view your status</p>
                        <ConnectButton />
                    </div>
                ) : (
                    <div className="space-y-8 animate-fade-in">
                        <div className="flex items-center gap-4">
                            <div className="w-14 h-14 rounded-xl bg-purple-500/20 flex items-center justify-center text-3xl">📊</div>
                            <div>
                                <h2 className="text-3xl font-bold text-white" style={{ fontFamily: 'Space Grotesk' }}>Your Dashboard</h2>
                                <p className="text-gray-400">Track your application and academic progress</p>
                            </div>
                        </div>

                        {/* Application Status Card */}
                        {application && application[0] !== '0x0000000000000000000000000000000000000000' && !hasEnrolled && (
                            <div className="glass-card p-8">
                                <div className="flex items-center gap-3 mb-6">
                                    <div className="w-10 h-10 rounded-lg bg-yellow-500/20 flex items-center justify-center text-xl">📝</div>
                                    <h3 className="text-xl font-semibold text-white" style={{ fontFamily: 'Space Grotesk' }}>Application Status</h3>
                                </div>

                                <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
                                    <div className="stat-card">
                                        <div className="stat-label">Name</div>
                                        <div className="text-white font-semibold mt-2">{application[1]}</div>
                                    </div>
                                    <div className="stat-card">
                                        <div className="stat-label">Faculty</div>
                                        <div className="text-white font-semibold mt-2">{application[2]}</div>
                                    </div>
                                    <div className="stat-card">
                                        <div className="stat-label">Major</div>
                                        <div className="text-white font-semibold mt-2">{application[3]}</div>
                                    </div>
                                    <div className="stat-card">
                                        <div className="stat-label">Status</div>
                                        <div className="mt-2">
                                            <span className={`badge ${getStatusBadge(applicationStatus).class}`}>
                                                {getStatusBadge(applicationStatus).text}
                                            </span>
                                        </div>
                                    </div>
                                </div>

                                {/* Enroll Button */}
                                {isApproved && enrollmentCost && (
                                    <div className="p-6 rounded-xl bg-green-500/10 border border-green-500/30">
                                        <div className="flex items-center gap-3 mb-4">
                                            <span className="text-2xl">🎉</span>
                                            <p className="text-green-400 font-medium">
                                                Congratulations! Your application has been approved.
                                            </p>
                                        </div>
                                        <p className="text-gray-400 mb-4">
                                            Complete your enrollment by paying the registration fee of <span className="text-white font-semibold">{formatEther(enrollmentCost)} ETH</span>
                                        </p>
                                        <button
                                            onClick={handleEnroll}
                                            disabled={enrollPending || enrollConfirming}
                                            className="px-8 py-4 btn-primary text-white font-semibold rounded-xl text-lg"
                                        >
                                            {enrollPending ? '⏳ Confirming...' : enrollConfirming ? '⛓️ Processing...' : `💰 Pay & Enroll (${formatEther(enrollmentCost)} ETH)`}
                                        </button>
                                        {enrollSuccess && (
                                            <p className="text-green-400 mt-4 flex items-center gap-2">
                                                <span>✅</span> Enrollment successful! Refresh to see your student data.
                                            </p>
                                        )}
                                    </div>
                                )}
                            </div>
                        )}

                        {/* Student Info Card (if enrolled) */}
                        {hasEnrolled && studentData && (
                            <div className="glass-card p-8">
                                <div className="flex items-center gap-3 mb-8">
                                    <div className="w-10 h-10 rounded-lg bg-purple-500/20 flex items-center justify-center text-xl">🎓</div>
                                    <h3 className="text-xl font-semibold text-white" style={{ fontFamily: 'Space Grotesk' }}>Student Information</h3>
                                </div>

                                {/* Main Stats */}
                                <div className="grid grid-cols-2 md:grid-cols-4 gap-6 mb-8">
                                    <div className="stat-card">
                                        <div className="stat-value">{studentData[5]}</div>
                                        <div className="stat-label">Semester</div>
                                    </div>
                                    <div className="stat-card">
                                        <div className="stat-value">{gpa ? (Number(gpa) / 100).toFixed(2) : '0.00'}</div>
                                        <div className="stat-label">GPA</div>
                                    </div>
                                    <div className="stat-card">
                                        <div className="text-3xl mb-2">{getStudentStatusText(studentData[6]).icon}</div>
                                        <div className={`font-semibold ${getStudentStatusText(studentData[6]).color}`}>
                                            {getStudentStatusText(studentData[6]).text}
                                        </div>
                                        <div className="stat-label">Status</div>
                                    </div>
                                    <div className="stat-card">
                                        <div className="text-3xl mb-2">📅</div>
                                        <div className="text-white text-sm font-semibold">{studentData[7]}</div>
                                        <div className="stat-label">Valid Until</div>
                                    </div>
                                </div>

                                {/* Student Details */}
                                <div className="grid md:grid-cols-2 gap-4">
                                    <div className="p-4 rounded-xl bg-white/5 border border-white/5">
                                        <span className="text-gray-400 text-sm">Student ID</span>
                                        <p className="text-white font-mono font-semibold text-lg">{studentData[0]}</p>
                                    </div>
                                    <div className="p-4 rounded-xl bg-white/5 border border-white/5">
                                        <span className="text-gray-400 text-sm">Full Name</span>
                                        <p className="text-white font-semibold text-lg">{studentData[1]}</p>
                                    </div>
                                    <div className="p-4 rounded-xl bg-white/5 border border-white/5">
                                        <span className="text-gray-400 text-sm">Email</span>
                                        <p className="text-white font-semibold">{studentData[2]}</p>
                                    </div>
                                    <div className="p-4 rounded-xl bg-white/5 border border-white/5">
                                        <span className="text-gray-400 text-sm">Faculty / Major</span>
                                        <p className="text-white font-semibold">{studentData[3]} - {studentData[4]}</p>
                                    </div>
                                </div>

                                {/* Graduation Info */}
                                {studentData[5] < 7 && !hasGraduated && (
                                    <div className="mt-6 p-5 rounded-xl bg-blue-500/10 border border-blue-500/30 flex items-center gap-4">
                                        <div className="text-3xl">📚</div>
                                        <div>
                                            <p className="text-blue-400 font-medium">Keep Going!</p>
                                            <p className="text-gray-400 text-sm">
                                                You are in semester {studentData[5]}. Graduation is available after completing semester 7.
                                            </p>
                                        </div>
                                    </div>
                                )}

                                {/* Claim Certificate */}
                                {hasGraduated && !hasClaimed && (
                                    <div className="mt-6 p-6 rounded-xl bg-gradient-to-r from-purple-500/20 to-pink-500/20 border border-purple-500/30">
                                        <div className="flex items-center gap-4 mb-4">
                                            <div className="text-4xl">🏆</div>
                                            <div>
                                                <p className="text-white font-semibold text-lg">Congratulations, Graduate!</p>
                                                <p className="text-gray-400">Claim your NFT certificate as proof of your achievement</p>
                                            </div>
                                        </div>
                                        <button
                                            onClick={handleClaimCertificate}
                                            disabled={claimPending || claimConfirming}
                                            className="px-8 py-4 btn-primary text-white font-semibold rounded-xl text-lg"
                                        >
                                            {claimPending ? '⏳ Confirming...' : claimConfirming ? '⛓️ Minting...' : '🏆 Claim Certificate NFT'}
                                        </button>
                                        {claimSuccess && (
                                            <p className="text-green-400 mt-4 flex items-center gap-2">
                                                <span>✅</span> Certificate NFT minted successfully!
                                            </p>
                                        )}
                                    </div>
                                )}

                                {hasClaimed && (
                                    <div className="mt-6 p-5 rounded-xl bg-green-500/10 border border-green-500/30 flex items-center gap-4">
                                        <div className="text-3xl">✅</div>
                                        <div>
                                            <p className="text-green-400 font-medium">Certificate Claimed</p>
                                            <p className="text-gray-400 text-sm">You have already claimed your graduation certificate NFT!</p>
                                        </div>
                                    </div>
                                )}
                            </div>
                        )}

                        {/* No Application */}
                        {(!application || application[0] === '0x0000000000000000000000000000000000000000') && !hasEnrolled && (
                            <div className="glass-card p-12 text-center">
                                <div className="w-20 h-20 mx-auto mb-6 rounded-full bg-purple-500/10 flex items-center justify-center text-4xl">📝</div>
                                <h3 className="text-2xl font-bold text-white mb-3" style={{ fontFamily: 'Space Grotesk' }}>No Application Found</h3>
                                <p className="text-gray-400 mb-8">You haven&apos;t applied for enrollment yet. Start your journey now!</p>
                                <Link
                                    href="/"
                                    className="inline-block px-8 py-4 btn-primary text-white font-semibold rounded-xl text-lg"
                                >
                                    📝 Apply for Enrollment
                                </Link>
                            </div>
                        )}
                    </div>
                )}
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
