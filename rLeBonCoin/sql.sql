CREATE TABLE `leboncoin` (
  `id` int(11) NOT NULL,
  `vehicle` longtext NOT NULL,
  `plate` varchar(12) NOT NULL,
  `price` int(20) NOT NULL,
  `owner` varchar(50) NOT NULL,
  `date` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

ALTER TABLE `leboncoin`
  ADD PRIMARY KEY (`id`);

ALTER TABLE `leboncoin`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;
COMMIT;