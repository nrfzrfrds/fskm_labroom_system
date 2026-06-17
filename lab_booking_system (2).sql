-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Jun 17, 2026 at 10:35 AM
-- Server version: 8.0.44
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `lab_booking_system`
--

-- --------------------------------------------------------

--
-- Table structure for table `bookings`
--

CREATE TABLE `bookings` (
  `bookingID` int NOT NULL,
  `dates` date DEFAULT NULL,
  `selectedRoom` varchar(100) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `userId` int NOT NULL,
  `userType` varchar(50) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `startTime` time DEFAULT NULL,
  `endTime` time DEFAULT NULL,
  `purpose` varchar(100) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `status` varchar(50) COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'Pending'
) ;

--
-- Dumping data for table `bookings`
--

INSERT INTO `bookings` (`bookingID`, `dates`, `selectedRoom`, `userId`, `userType`, `startTime`, `endTime`, `purpose`, `status`) VALUES
(1, '2026-06-09', 'lab 1', 12, 'student', '08:00:00', '11:00:00', 'practical', 'rejected'),
(2, '2026-06-09', 'lab 1', 13, 'lecturer', '12:00:00', '14:00:00', 'event', 'approved'),
(3, '2026-06-09', 'Mathematics & Computer Science Research Laboratory 2', 12, 'student', '08:00:00', '09:00:00', 'mukbang', 'approved'),
(4, '2026-06-09', 'lab 1', 12, 'student', '10:00:00', '11:00:00', 'class', 'approved'),
(5, '2026-06-10', 'lab 1', 4, 'student', '08:00:00', '09:00:00', 'event', 'approved'),
(8, '2026-06-11', 'Programming Laboratory 1', 4, 'student', '08:00:00', '09:00:00', 'event', 'approved'),
(9, '2026-06-11', 'Programming Laboratory 1', 3, 'lecturer', '10:00:00', '11:00:00', 'event', 'approved'),
(10, '2026-06-11', 'Programming Laboratory 2', 4, 'student', '08:00:00', '09:00:00', 'class', 'approved'),
(11, '2026-06-10', 'Programming Laboratory 2', 6, 'student', '08:00:00', '09:00:00', 'event', 'approved'),
(12, '2026-06-16', 'Programming Lab I', 6, 'student', '08:00:00', '09:00:00', 'event', 'approved'),
(13, '2026-06-21', 'Programming Lab 2', 6, 'student', '11:00:00', '12:00:00', 'event', 'approved');

-- --------------------------------------------------------

--
-- Table structure for table `lab_rooms`
--

CREATE TABLE `lab_rooms` (
  `room_id` int NOT NULL,
  `name` varchar(100) NOT NULL,
  `capacity` int DEFAULT NULL,
  `location` varchar(255) DEFAULT NULL,
  `status` enum('AVAILABLE','MAINTENANCE') DEFAULT 'AVAILABLE',
  `description` varchar(255) DEFAULT 'Standard computer laboratory.'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `lab_rooms`
--

INSERT INTO `lab_rooms` (`room_id`, `name`, `capacity`, `location`, `status`, `description`) VALUES
(1, 'Programming Lab I', 57, 'FSKM, Level 1', 'AVAILABLE', 'Standard computer laboratory.'),
(2, 'CISCO Networking Standard Laboratory', 49, 'FSKM, Level 2', 'AVAILABLE', 'Standard computer laboratory.'),
(3, 'Programming Lab 2', 57, 'FSKM, Level 1', 'AVAILABLE', 'Standard computer laboratory.'),
(4, 'Programming Lab 3', 57, 'FSKM, Level 2', 'AVAILABLE', 'Standard computer laboratory.'),
(5, 'Mobile Computing Lab', 20, 'FSKM, Level 1', 'AVAILABLE', 'Standard computer laboratory.'),
(6, 'CERMAT Laboratory', 54, 'FSKM, Level 2', 'AVAILABLE', 'Standard computer laboratory.'),
(7, 'AL-SAFA Laboratory', 72, NULL, 'AVAILABLE', 'Standard computer laboratory.'),
(8, 'Mathematics & Computer Science Research Laboratory 1', 24, NULL, 'AVAILABLE', 'Standard computer laboratory.'),
(9, 'Mathematics & Computer Science Research Laboratory 2', 24, NULL, 'AVAILABLE', 'Standard computer laboratory.');

-- --------------------------------------------------------

--
-- Table structure for table `lab_schedules`
--

CREATE TABLE `lab_schedules` (
  `schedule_id` int NOT NULL,
  `room_id` int DEFAULT NULL,
  `day_of_week` int DEFAULT NULL,
  `tahun` int DEFAULT NULL,
  `start_time` time DEFAULT NULL,
  `end_time` time DEFAULT NULL,
  `subject_info` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `lab_schedules`
--

INSERT INTO `lab_schedules` (`schedule_id`, `room_id`, `day_of_week`, `tahun`, `start_time`, `end_time`, `subject_info`) VALUES
(1, 7, 1, 1, '11:00:00', '13:00:00', 'MDA3033-K2-Hilmi'),
(2, 7, 1, 1, '14:00:00', '16:00:00', 'MDA3033-K2-Hilmi'),
(3, 7, 1, 1, '16:00:00', '18:00:00', 'MTM3034-K2-Syerina'),
(4, 7, 1, 2, '08:00:00', '11:00:00', 'MKG3004-K1-Chong'),
(5, 7, 1, 3, '08:00:00', '11:00:00', 'MKG3004-K1-Chong'),
(6, 7, 2, 1, '11:00:00', '13:00:00', 'MDA3033-K1-Madihah'),
(7, 7, 2, 1, '14:00:00', '17:00:00', 'MTM3044-K1-Aidya'),
(8, 7, 3, 1, '08:00:00', '11:00:00', 'MTM3044-K2-Fadilah'),
(9, 7, 3, 1, '11:00:00', '13:00:00', 'MTM3034_K1-Azlida'),
(10, 7, 3, 1, '14:00:00', '16:00:00', 'MTM3034-K1'),
(11, 7, 3, 1, '16:00:00', '18:00:00', 'MTK3063-K1 Sakinah'),
(12, 7, 4, 1, '10:00:00', '13:00:00', 'MTK3063-K2-Syerina'),
(13, 7, 4, 2, '14:00:00', '17:00:00', 'MKG3004-K2-Azwani'),
(14, 7, 4, 3, '14:00:00', '17:00:00', 'MKG3004-K2-Azwani'),
(15, 7, 5, 1, '10:00:00', '13:00:00', 'MTK3063-K3-Azlida'),
(16, 6, 1, 2, '11:00:00', '13:00:00', 'MDA3103-Zabidin'),
(17, 6, 2, 2, '14:00:00', '16:00:00', 'MTM4994'),
(18, 6, 2, 3, '14:00:00', '16:00:00', 'MTM4994'),
(19, 6, 3, 1, '11:00:00', '13:00:00', 'MDA3044-K1-Kak Choon'),
(20, 6, 3, 2, '14:00:00', '16:00:00', 'FIS3813-K1-Dr. Aslina'),
(21, 6, 4, 1, '11:00:00', '13:00:00', 'MDA3044-K2-Kak Choon'),
(22, 6, 4, 2, '14:00:00', '16:00:00', 'FIS3243-K1-Dr. Shazana'),
(23, 6, 5, 2, '11:00:00', '13:00:00', 'MKG3033-K1-Kak Choon'),
(24, 4, 3, 2, '14:00:00', '17:00:00', 'CSA3023 - Sir Syaffieq'),
(26, 3, 1, 1, '08:00:00', '10:00:00', 'CSA1233');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `userID` int NOT NULL,
  `name` varchar(100) NOT NULL,
  `institutionID` varchar(50) NOT NULL DEFAULT '',
  `email` varchar(120) NOT NULL,
  `phoneNum` varchar(20) NOT NULL,
  `userType` varchar(20) NOT NULL,
  `password` varchar(255) NOT NULL,
  `profilePic` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`userID`, `name`, `institutionID`, `email`, `phoneNum`, `userType`, `password`, `profilePic`) VALUES
(2, 'WAN FATIN FATIHAH YAHYA', 'ST001', 'st001@umt.edu.my', '0198765432', 'staff', 'fatin!', '/uploads/profile-pictures/st001_umt_edu_my_8c78367dd8304e069a15b9b068cd3478.png'),
(3, 'ZURIANA BINTI ABU BAKAR', 'L12345', 'l12345@umt.edu.my', '0123456789', 'lecturer', 'zuriana@', '/uploads/profile-pictures/l12345_umt_edu_my_bf9b707b35934e93ae8ce3b3122999b4.jpg'),
(5, 'ASMAWATI NGAH', 'ST002', 'st002@umt.edu.my', '0133226789', 'staff', 'asma!', NULL),
(6, 'Nur Adlina binti Muharizan', 's76855', 's76855@umt.edu.my', '0199228071', 'student', 'Adlina#', '/uploads/profile-pictures/s76855_umt_edu_my_0167cea80d874a909a19303716b9fdcb.jpg');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `bookings`
--
ALTER TABLE `bookings`
  ADD PRIMARY KEY (`bookingID`);

--
-- Indexes for table `lab_rooms`
--
ALTER TABLE `lab_rooms`
  ADD PRIMARY KEY (`room_id`);

--
-- Indexes for table `lab_schedules`
--
ALTER TABLE `lab_schedules`
  ADD PRIMARY KEY (`schedule_id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`userID`),
  ADD UNIQUE KEY `email` (`email`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `bookings`
--
ALTER TABLE `bookings`
  MODIFY `bookingID` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `lab_rooms`
--
ALTER TABLE `lab_rooms`
  MODIFY `room_id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT for table `lab_schedules`
--
ALTER TABLE `lab_schedules`
  MODIFY `schedule_id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=28;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `userID` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
