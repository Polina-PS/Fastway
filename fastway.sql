-- phpMyAdmin SQL Dump
-- version 5.2.0
-- https://www.phpmyadmin.net/
--
-- Хост: 127.0.0.1:3306
-- Время создания: Апр 05 2024 г., 19:46
-- Версия сервера: 5.7.39-log
-- Версия PHP: 8.1.9

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- База данных: `fastway`
--

DELIMITER $$
--
-- Процедуры
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `procedura_count` (IN `count_seats` INT, IN `p_id_class` INT, OUT `p_carriage` INT, OUT `p_seat` INT)   BEGIN
    DECLARE total_carriages INT;
    DECLARE seats_per_carriage INT;
    
    SELECT number_carriage, number_seats_in_carriage INTO total_carriages, seats_per_carriage FROM class WHERE id_class = p_id_class;
    
    SET p_carriage = 1;
    SET p_seat = count_seats;
    
    WHILE p_seat > seats_per_carriage DO
        SET p_seat = p_seat - seats_per_carriage;
        SET p_carriage = p_carriage + 1;
    END WHILE;
    
    CASE p_id_class
        WHEN 1 THEN SET p_carriage = p_carriage + 1; 
        WHEN 2 THEN SET p_carriage = p_carriage + 5; 
        WHEN 3 THEN SET p_carriage = p_carriage + 8; 
    END CASE;
	SELECT p_carriage, p_seat;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `procedura_count_main` (IN `date_flight` DATE, IN `p_id_flight` INT, IN `p_id_class` INT, OUT `count_seats` INT, OUT `p_carriage` INT, OUT `p_seat` INT)   BEGIN
    DECLARE i INT;
    DECLARE p_main_carriage INT;
    DECLARE p_main_seat INT;
   
    
    CALL procedure_curdate(date_flight, i);
    
    SET @sql = CONCAT('SELECT day_', i, ' INTO @count_seats FROM Number_seats WHERE id_flight = ', p_id_flight, ' AND id_class = ', p_id_class);
    
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    SET count_seats = @count_seats; 
    
    SELECT count_seats; 

    CALL procedura_count(count_seats, p_id_class, p_main_carriage, p_main_seat);
    SET p_carriage = p_main_carriage; 
    SET p_seat = p_main_seat; 
    
    DEALLOCATE PREPARE stmt;
    SET @sql = CONCAT('UPDATE Number_seats SET day_', i, ' = day_', i, ' - 1 WHERE id_flight = ', p_id_flight, ' AND id_class = ', p_id_class);
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `procedure_buy_ticket` (IN `p_id_ticket` INT, OUT `count_seats` INT, OUT `p_carriage` INT, OUT `p_seat` INT)   BEGIN
    DECLARE i INT;
    DECLARE p_main_carriage INT;
    DECLARE p_main_seat INT;
    declare p_date_flight date;
    declare p_id_class int;
    declare p_id_flight int;
    
    SELECT id_flight, id_class, date_flight INTO p_id_flight, p_id_class, p_date_flight FROM Ticket WHERE id_ticket = p_id_ticket;
    
    CALL procedura_count_main(p_date_flight, p_id_flight, p_id_class, count_seats, p_carriage, p_seat);
    UPDATE Ticket SET seat = p_seat, carriage = p_carriage WHERE id_ticket = p_id_ticket;
    SELECT p_id_flight, p_id_class, p_date_flight, p_seat, p_carriage;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `procedure_carriage_seat` (IN `date_flight` DATE, IN `p_id_flight` INT, IN `p_id_class` INT, OUT `count_seats` INT, OUT `p_carriage` INT, OUT `p_seat` INT)   BEGIN
	DECLARE i INT;
    DECLARE p_main_carriage INT;
    DECLARE p_main_seat INT;
   
    
    CALL procedure_curdate(date_flight, i);
    
    SET @sql = CONCAT('SELECT day_', i, ' INTO @count_seats FROM Number_seats WHERE id_flight = ', p_id_flight, ' AND id_class = ', p_id_class);
    
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    SET count_seats = @count_seats; 
    
    SELECT count_seats; 

    CALL procedura_count(count_seats, p_id_class, p_main_carriage, p_main_seat);
    SET p_carriage = p_main_carriage; 
    SET p_seat = p_main_seat; 
    
    SELECT p_carriage, p_seat;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `procedure_curdate` (IN `flight_day` DATE, OUT `day_i` INT)   BEGIN
    DECLARE today DATE;
    DECLARE diff_days INT;

    SET today = CURDATE();
    SET diff_days = DATEDIFF(flight_day, today);
    SET day_i = diff_days + 1;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `procedure_day_class` (IN `day_i` VARCHAR(255), IN `id_flight` INT, IN `id_class` INT, OUT `count_seats` INT)   BEGIN
    SET @sql = CONCAT('SELECT ', day_i, ' INTO @count_seats FROM Number_seats WHERE id_flight = ', id_flight, ' and id_class = ', id_class);
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    SET count_seats = @count_seats;
    DEALLOCATE PREPARE stmt;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `procedure_ns_buy_ticket` (IN `i` INT)   BEGIN
    SET @sql = CONCAT('UPDATE Number_seats ns INNER JOIN Ticket t ON ns.id_flight = t.id_flight SET day_', i, ' = day_', i, '-1');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `procedure_ns_day_14` ()   UPDATE Number_seats ns 
    INNER JOIN Class c ON ns.id_class = c.id_class 
    SET ns.day_14 = c.number_carriage * c.number_seats_in_carriage$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `procedure_ns_day_i` ()   BEGIN
    DECLARE i INT DEFAULT 1;
    WHILE i < 15 DO
        SET @sql = CONCAT('UPDATE Number_seats ns INNER JOIN Class c ON ns.id_class = c.id_class SET ns.day_', i, ' = c.number_carriage * c.number_seats_in_carriage');
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
        SET i = i + 1;
    END WHILE;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `procedure_price_flight` (IN `p_id_flight` INT, IN `p_id_class` INT, OUT `p_price` DECIMAL)   BEGIN
    DECLARE flight_price DECIMAL(10,2);

    SELECT price INTO flight_price FROM Flight WHERE id_flight = p_id_flight;
    SET p_price = flight_price + (SELECT price FROM Class WHERE id_class = p_id_class);
    SELECT p_price as price;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `procedure_update_seats_days` ()   BEGIN
    DECLARE i INT DEFAULT 1;
    
    WHILE i < 14 DO
        SET @sql = CONCAT('UPDATE Number_seats SET day_', i, ' = day_', i+1);
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
        SET i = i + 1;
    END WHILE;

    UPDATE Number_seats
    SET day_14 = 100;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `update_dates` ()   BEGIN
 UPDATE Today SET day = CURDATE() WHERE id_day = 1;
 UPDATE Today SET day = CURDATE() + INTERVAL 1 DAY WHERE id_day = 2;
 UPDATE Today SET day = CURDATE() + INTERVAL 2 DAY WHERE id_day = 3;
 UPDATE Today SET day = CURDATE() + INTERVAL 3 DAY WHERE id_day = 4;
 UPDATE Today SET day = CURDATE() + INTERVAL 4 DAY WHERE id_day = 5;
 UPDATE Today SET day = CURDATE() + INTERVAL 5 DAY WHERE id_day = 6;
 UPDATE Today SET day = CURDATE() + INTERVAL 6 DAY WHERE id_day = 7;
 UPDATE Today SET day = CURDATE() + INTERVAL 7 DAY WHERE id_day = 8;
 UPDATE Today SET day = CURDATE() + INTERVAL 8 DAY WHERE id_day = 9;
 UPDATE Today SET day = CURDATE() + INTERVAL 9 DAY WHERE id_day = 10;
 UPDATE Today SET day = CURDATE() + INTERVAL 10 DAY WHERE id_day = 11;
 UPDATE Today SET day = CURDATE() + INTERVAL 11 DAY WHERE id_day = 12;
 UPDATE Today SET day = CURDATE() + INTERVAL 12 DAY WHERE id_day = 13;
 UPDATE Today SET day = CURDATE() + INTERVAL 13 DAY WHERE id_day = 14;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Структура таблицы `City`
--

CREATE TABLE `City` (
  `id_city` int(11) NOT NULL,
  `name_city` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Дамп данных таблицы `City`
--

INSERT INTO `City` (`id_city`, `name_city`) VALUES
(6, 'Адлер'),
(3, 'Казань'),
(7, 'Краснодар'),
(1, 'Москва'),
(4, 'Нижний Новгород'),
(2, 'Санкт-Петербург'),
(5, 'Сочи');

-- --------------------------------------------------------

--
-- Структура таблицы `Class`
--

CREATE TABLE `Class` (
  `id_class` int(11) NOT NULL,
  `name_class` varchar(255) DEFAULT NULL,
  `number_carriage` int(11) DEFAULT NULL,
  `number_seats_in_carriage` int(11) DEFAULT NULL,
  `price` decimal(10,2) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Дамп данных таблицы `Class`
--

INSERT INTO `Class` (`id_class`, `name_class`, `number_carriage`, `number_seats_in_carriage`, `price`) VALUES
(1, 'Эконом', 5, 50, '800.00'),
(2, 'Премиум', 3, 30, '2000.00'),
(3, 'Люкс', 2, 10, '5000.00');

-- --------------------------------------------------------

--
-- Структура таблицы `Client`
--

CREATE TABLE `Client` (
  `id_client` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `last_name` varchar(255) NOT NULL,
  `father_name` varchar(255) DEFAULT NULL,
  `series` varchar(4) NOT NULL,
  `number` varchar(6) NOT NULL,
  `birthday` date NOT NULL,
  `mail` varchar(255) DEFAULT NULL,
  `phone` text
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Дамп данных таблицы `Client`
--

INSERT INTO `Client` (`id_client`, `name`, `last_name`, `father_name`, `series`, `number`, `birthday`, `mail`, `phone`) VALUES
(1, 'Гюней ', 'Керимова', 'Рахмановна', '1111', '111111', '2003-01-07', 'gk@mail.ru', '89009009999'),
(2, 'Полина', 'Плотникова', 'Сергеевна', '7800', '333333', '2001-11-03', 'Plotnikova-PS@yandex.ru', '12345678901'),
(3, 'Али', 'Алиев', 'Алиевич', '3040', '224568', '2002-03-20', 'wew@mail.ru', '89463747172'),
(29, 'Зюзя', 'Зюзяев', 'Зюзевич', '3333', '333333', '2003-03-30', 'zuza@mail.ru', '83333333333'),
(34, 'Мария', 'Киба', 'Романовна', '1234', '567890', '1991-10-30', 'kkk@mail.ru', '12345678901'),
(41, 'wBERCUBWOQRVUBW', 'HABVDCHVkhwcd', 'WQRVUQBWRIVB', '3433', '343243', '2003-09-09', 'FVJNLNEWLV', '3425352343'),
(42, 'я', 'я', 'я', '4444', '444444', '2007-07-07', 'пр', '1'),
(43, 'УЦАГпцуа', 'йацаЦУА', 'ацуГНАПШцу', '2132', '21323', '2003-01-07', 'уацуац', '34234532'),
(44, 'УВАПшгЦПУШКГА', 'фивуалфиПагп', 'УАПУЩГПЦАШГ', '2464', '342432', '2002-02-20', 'ЦКПАРЦКРПА', '242352345234'),
(45, 'Ляли', 'Ляли', 'Ляли', '2432', '342432', '2002-02-20', 'ЦКПАРЦКРПА', '242352345234'),
(46, 'Полина', 'Плотникова', 'Олеговна', '7800', '333333', '2001-11-03', 'Plotnikova-PS@yandex.ru', '12345678901'),
(47, 'Полина', 'вапролдж', 'Олеговна', '7800', '333333', '2001-11-03', 'Plotnikova-PS@yandex.ru', '12345678345'),
(48, 'вапрноглш', 'вапролдж', 'Олеговна', '7800', '333333', '2001-11-03', 'Plotnikova-PS@yandex.ru', '12345678345'),
(49, 'Полина', 'Плотникова', 'kjhgfds', '2345', '123456', '2020-04-02', 'Plotnikova-PS@yandex.ru', '12345678901'),
(50, 'rtyuio', 'sdfghjkl', 'vbnm', '3333', '999999', '2020-04-02', 'Plotnikova-PS@yandex.ru', '12345678901'),
(51, 'Полина', 'Плотникова', 'fdsa', '7800', '333333', '2020-04-02', 'Plotnikova-PS@yandex.ru', '12345678901'),
(52, 'Полина', 'Плотникова', 'vbnm', '4444', '999999', '2020-04-02', 'Plotnikova-PS@yandex.ru', '12345678345'),
(53, 'dfghj', 'asdfghjkl', 'fghj', '2345', '456788', '2024-04-02', 'sdfg', '2345678888');

-- --------------------------------------------------------

--
-- Структура таблицы `Flight`
--

CREATE TABLE `Flight` (
  `id_flight` int(11) NOT NULL,
  `flight_number` varchar(255) DEFAULT NULL,
  `id_train` int(11) DEFAULT NULL,
  `id_station_1` int(11) DEFAULT NULL,
  `id_station_2` int(11) DEFAULT NULL,
  `time_way` time DEFAULT NULL,
  `time_start` time DEFAULT NULL,
  `time_end` time DEFAULT NULL,
  `price` decimal(10,2) DEFAULT NULL,
  `number_train` varchar(255) DEFAULT NULL,
  `city_1` varchar(255) DEFAULT NULL,
  `city_2` varchar(255) DEFAULT NULL,
  `station_1` varchar(255) DEFAULT NULL,
  `station_2` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Дамп данных таблицы `Flight`
--

INSERT INTO `Flight` (`id_flight`, `flight_number`, `id_train`, `id_station_1`, `id_station_2`, `time_way`, `time_start`, `time_end`, `price`, `number_train`, `city_1`, `city_2`, `station_1`, `station_2`) VALUES
(1, 'Р11', 1, 5, 13, '10:00:00', '01:00:00', '11:00:00', '2000.00', '011К', 'Москва', 'Сочи', 'Белорусский', 'Сочи'),
(2, 'Р12', 1, 13, 5, '10:00:00', '11:30:00', '21:30:00', '2100.00', '011К', 'Сочи', 'Москва', 'Сочи', 'Белорусский'),
(3, 'Р13', 2, 6, 11, '11:00:00', '00:30:00', '11:30:00', '1900.00', '012К', 'Москва', 'Казань', 'Ярославский', 'Казань'),
(4, 'Р14', 2, 11, 6, '11:00:00', '12:00:00', '23:00:00', '1900.00', '012К', 'Казань', 'Москва', 'Казань', 'Ярославский'),
(5, 'Р15', 5, 1, 8, '03:45:00', '06:00:00', '09:45:00', '2500.00', '051С', 'Москва', 'Санкт-Петербург', 'Ленинградский', 'Главный'),
(6, 'Р16', 5, 8, 1, '03:45:00', '09:00:00', '12:45:00', '2700.00', '051С', 'Санкт-Петербург', 'Москва', 'Главный', 'Ленинградский'),
(7, 'Р17', 7, 2, 12, '04:30:00', '07:30:00', '12:00:00', '1500.00', '031Л', 'Москва', 'Нижний Новгород', 'Курский', 'Нижний Новгород'),
(8, 'Р18', 7, 12, 2, '04:30:00', '14:00:00', '18:30:00', '1600.00', '031Л', 'Нижний Новгород', 'Москва', 'Нижний Новгород', 'Курский'),
(9, 'Р19', 8, 9, 6, '03:00:00', '16:00:00', '19:00:00', '1000.00', '041Л', 'Санкт-Петербург', 'Москва', 'Витебский', 'Ярославский'),
(10, 'Р20', 8, 6, 9, '03:00:00', '12:00:00', '15:00:00', '1000.00', '041Л', 'Москва', 'Санкт-Петербург', 'Ярославский', 'Витебский');

-- --------------------------------------------------------

--
-- Структура таблицы `Number_seats`
--

CREATE TABLE `Number_seats` (
  `id_number_seats` int(11) NOT NULL,
  `id_flight` int(11) DEFAULT NULL,
  `id_class` int(11) DEFAULT NULL,
  `day_1` int(11) DEFAULT NULL,
  `day_2` int(11) DEFAULT NULL,
  `day_3` int(11) DEFAULT NULL,
  `day_4` int(11) DEFAULT NULL,
  `day_5` int(11) DEFAULT NULL,
  `day_6` int(11) DEFAULT NULL,
  `day_7` int(11) DEFAULT NULL,
  `day_8` int(11) DEFAULT NULL,
  `day_9` int(11) DEFAULT NULL,
  `day_10` int(11) DEFAULT NULL,
  `day_11` int(11) DEFAULT NULL,
  `day_12` int(11) DEFAULT NULL,
  `day_13` int(11) DEFAULT NULL,
  `day_14` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Дамп данных таблицы `Number_seats`
--

INSERT INTO `Number_seats` (`id_number_seats`, `id_flight`, `id_class`, `day_1`, `day_2`, `day_3`, `day_4`, `day_5`, `day_6`, `day_7`, `day_8`, `day_9`, `day_10`, `day_11`, `day_12`, `day_13`, `day_14`) VALUES
(11, 1, 1, 245, 249, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250),
(12, 1, 2, 86, 87, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90),
(13, 1, 3, 19, 19, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20),
(14, 2, 1, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250),
(15, 2, 2, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90),
(16, 2, 3, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20),
(17, 3, 1, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250),
(18, 3, 2, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90),
(19, 3, 3, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20),
(20, 4, 1, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250),
(21, 4, 2, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90),
(22, 4, 3, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20),
(23, 5, 1, 250, 249, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250),
(24, 5, 2, 90, 90, 90, 88, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90),
(25, 5, 3, 20, 20, 19, 19, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20),
(26, 6, 1, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250),
(27, 6, 2, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90),
(28, 6, 3, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20),
(32, 7, 1, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250),
(33, 7, 2, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90),
(34, 7, 3, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20),
(35, 8, 1, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250),
(36, 8, 2, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90),
(37, 8, 3, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20),
(38, 9, 1, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250),
(39, 9, 2, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90),
(40, 9, 3, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20),
(41, 10, 1, 250, 250, 250, 250, 250, 249, 250, 250, 250, 250, 250, 250, 250, 250),
(42, 10, 2, 90, 89, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90),
(43, 10, 3, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20);

-- --------------------------------------------------------

--
-- Структура таблицы `Station`
--

CREATE TABLE `Station` (
  `id_station` int(11) NOT NULL,
  `id_city` int(11) DEFAULT NULL,
  `name_station` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Дамп данных таблицы `Station`
--

INSERT INTO `Station` (`id_station`, `id_city`, `name_station`) VALUES
(1, 1, 'Ленинградский'),
(2, 1, 'Курский'),
(3, 1, 'Киевский'),
(4, 1, 'Казанский'),
(5, 1, 'Белорусский'),
(6, 1, 'Ярославский'),
(7, 1, 'Павелецкий'),
(8, 2, 'Главный'),
(9, 2, 'Витебский'),
(10, 2, 'Ладожский'),
(11, 3, 'Казань'),
(12, 4, 'Нижний Новгород'),
(13, 5, 'Сочи'),
(14, 6, 'Адлер'),
(15, 7, 'Краснодар');

-- --------------------------------------------------------

--
-- Структура таблицы `Ticket`
--

CREATE TABLE `Ticket` (
  `id_ticket` int(11) NOT NULL,
  `id_client` int(11) DEFAULT NULL,
  `id_flight` int(11) DEFAULT NULL,
  `date_flight` date DEFAULT NULL,
  `price` decimal(10,2) DEFAULT '0.00',
  `id_class` int(11) DEFAULT NULL,
  `carriage` int(11) DEFAULT NULL,
  `seat` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Дамп данных таблицы `Ticket`
--

INSERT INTO `Ticket` (`id_ticket`, `id_client`, `id_flight`, `date_flight`, `price`, `id_class`, `carriage`, `seat`) VALUES
(28, 41, 1, '2024-02-28', '4000.00', 2, 8, 28),
(29, 42, 1, '2024-02-29', '4000.00', 2, 8, 30),
(30, 43, 1, '2024-02-26', '2800.00', 1, 6, 50),
(31, 44, 1, '2024-03-05', '4000.00', 2, 8, 30),
(32, 45, 5, '2024-03-06', '4500.00', 2, 8, 30),
(33, 46, 1, '2024-04-05', '2800.00', 1, 6, 48),
(34, 47, 1, '2024-04-05', '2800.00', 1, 6, 47),
(35, 48, 1, '2024-04-05', '2800.00', 1, 6, 46),
(36, 2, 1, '2024-04-05', '4000.00', 2, 8, 27),
(37, 2, 10, '2024-04-06', '3000.00', 2, 8, 30),
(38, 49, 1, '2024-04-06', '4000.00', 2, 8, 29),
(39, 50, 1, '2024-04-06', '7000.00', 3, 10, 10),
(40, 51, 1, '2024-04-06', '4000.00', 2, 8, 28),
(41, 49, 5, '2024-04-06', '3300.00', 1, 6, 50),
(42, 46, 5, '2024-04-08', '4500.00', 2, 8, 30),
(43, 2, 5, '2024-04-08', '7500.00', 3, 10, 10),
(44, 52, 5, '2024-04-08', '7500.00', 3, 10, 10),
(45, 2, 5, '2024-04-08', '4500.00', 2, 8, 29),
(46, 34, 10, '2024-04-10', '1800.00', 1, 6, 50),
(47, 53, 1, '2024-04-06', '2800.00', 1, 6, 50);

--
-- Триггеры `Ticket`
--
DELIMITER $$
CREATE TRIGGER `calculate_ticket_price` BEFORE INSERT ON `Ticket` FOR EACH ROW begin
DECLARE flight_price DECIMAL(10,2);
    
    SELECT price INTO flight_price FROM Flight WHERE id_flight = NEW.id_flight;
    
    SET NEW.price = flight_price + (SELECT price FROM Class WHERE id_class = NEW.id_class);
end
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `calculate_ticket_price_update` BEFORE UPDATE ON `Ticket` FOR EACH ROW BEGIN
	declare flight_price decimal(10, 2);
    declare class_price decimal(10, 2);
    select price into flight_price from Flight WHERE id_flight= NEW.id_flight;
    select price into class_price from Class where id_class = New.id_class;
    set new.price= flight_price+class_price;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Структура таблицы `Today`
--

CREATE TABLE `Today` (
  `id_day` int(11) NOT NULL,
  `day` date DEFAULT NULL,
  `day_i` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Дамп данных таблицы `Today`
--

INSERT INTO `Today` (`id_day`, `day`, `day_i`) VALUES
(1, '2024-04-05', 'day_1'),
(2, '2024-04-06', 'day_2'),
(3, '2024-04-07', 'day_3'),
(4, '2024-04-08', 'day_4'),
(5, '2024-04-09', 'day_5'),
(6, '2024-04-10', 'day_6'),
(7, '2024-04-11', 'day_7'),
(8, '2024-04-12', 'day_8'),
(9, '2024-04-13', 'day_9'),
(10, '2024-04-14', 'day_10'),
(11, '2024-04-15', 'day_11'),
(12, '2024-04-16', 'day_12'),
(13, '2024-04-17', 'day_13'),
(14, '2024-04-18', 'day_14');

-- --------------------------------------------------------

--
-- Структура таблицы `Train`
--

CREATE TABLE `Train` (
  `id_train` int(11) NOT NULL,
  `id_train_category` int(11) DEFAULT NULL,
  `number_train` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Дамп данных таблицы `Train`
--

INSERT INTO `Train` (`id_train`, `id_train_category`, `number_train`) VALUES
(1, 1, '011К'),
(2, 1, '012К'),
(3, 1, '021К'),
(4, 1, '022К'),
(5, 2, '051С'),
(6, 2, '061С'),
(7, 3, '031Л'),
(8, 3, '041Л');

-- --------------------------------------------------------

--
-- Структура таблицы `Train_category`
--

CREATE TABLE `Train_category` (
  `id_train_category` int(11) NOT NULL,
  `name_train_category` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Дамп данных таблицы `Train_category`
--

INSERT INTO `Train_category` (`id_train_category`, `name_train_category`) VALUES
(1, 'Классический '),
(2, 'Сапсан'),
(3, 'Ласточка');

--
-- Индексы сохранённых таблиц
--

--
-- Индексы таблицы `City`
--
ALTER TABLE `City`
  ADD PRIMARY KEY (`id_city`),
  ADD UNIQUE KEY `index_city_1` (`name_city`);

--
-- Индексы таблицы `Class`
--
ALTER TABLE `Class`
  ADD PRIMARY KEY (`id_class`);

--
-- Индексы таблицы `Client`
--
ALTER TABLE `Client`
  ADD PRIMARY KEY (`id_client`);

--
-- Индексы таблицы `Flight`
--
ALTER TABLE `Flight`
  ADD PRIMARY KEY (`id_flight`),
  ADD KEY `index_flight_id_train` (`id_train`),
  ADD KEY `index_flight_id_station_1` (`id_station_1`),
  ADD KEY `index_flight_id_station_2` (`id_station_2`),
  ADD KEY `i_tr` (`number_train`),
  ADD KEY `i_city` (`city_1`),
  ADD KEY `i_city2` (`city_2`),
  ADD KEY `i_station2` (`station_2`),
  ADD KEY `i_station1` (`station_1`);

--
-- Индексы таблицы `Number_seats`
--
ALTER TABLE `Number_seats`
  ADD PRIMARY KEY (`id_number_seats`),
  ADD KEY `index_number_seats_id_class` (`id_class`),
  ADD KEY `index_number_seats_id_flight` (`id_flight`);

--
-- Индексы таблицы `Station`
--
ALTER TABLE `Station`
  ADD PRIMARY KEY (`id_station`),
  ADD UNIQUE KEY `index_station` (`name_station`),
  ADD KEY `index_station_id_city` (`id_city`);

--
-- Индексы таблицы `Ticket`
--
ALTER TABLE `Ticket`
  ADD PRIMARY KEY (`id_ticket`),
  ADD KEY `index_ticket_id_client` (`id_client`),
  ADD KEY `index_ticket_id_flight` (`id_flight`),
  ADD KEY `index_ticket_id_class` (`id_class`),
  ADD KEY `index_today_day` (`date_flight`);

--
-- Индексы таблицы `Today`
--
ALTER TABLE `Today`
  ADD PRIMARY KEY (`id_day`);

--
-- Индексы таблицы `Train`
--
ALTER TABLE `Train`
  ADD PRIMARY KEY (`id_train`),
  ADD UNIQUE KEY `index_tr` (`number_train`),
  ADD KEY `index_train_category_id_train_category` (`id_train_category`);

--
-- Индексы таблицы `Train_category`
--
ALTER TABLE `Train_category`
  ADD PRIMARY KEY (`id_train_category`);

--
-- AUTO_INCREMENT для сохранённых таблиц
--

--
-- AUTO_INCREMENT для таблицы `City`
--
ALTER TABLE `City`
  MODIFY `id_city` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT для таблицы `Class`
--
ALTER TABLE `Class`
  MODIFY `id_class` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT для таблицы `Client`
--
ALTER TABLE `Client`
  MODIFY `id_client` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=54;

--
-- AUTO_INCREMENT для таблицы `Flight`
--
ALTER TABLE `Flight`
  MODIFY `id_flight` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT для таблицы `Number_seats`
--
ALTER TABLE `Number_seats`
  MODIFY `id_number_seats` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=44;

--
-- AUTO_INCREMENT для таблицы `Station`
--
ALTER TABLE `Station`
  MODIFY `id_station` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=16;

--
-- AUTO_INCREMENT для таблицы `Ticket`
--
ALTER TABLE `Ticket`
  MODIFY `id_ticket` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=48;

--
-- AUTO_INCREMENT для таблицы `Today`
--
ALTER TABLE `Today`
  MODIFY `id_day` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=15;

--
-- AUTO_INCREMENT для таблицы `Train`
--
ALTER TABLE `Train`
  MODIFY `id_train` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT для таблицы `Train_category`
--
ALTER TABLE `Train_category`
  MODIFY `id_train_category` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- Ограничения внешнего ключа сохраненных таблиц
--

--
-- Ограничения внешнего ключа таблицы `Flight`
--
ALTER TABLE `Flight`
  ADD CONSTRAINT `flight_ibfk_1` FOREIGN KEY (`id_station_1`) REFERENCES `Station` (`id_station`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `flight_ibfk_2` FOREIGN KEY (`id_station_2`) REFERENCES `Station` (`id_station`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `flight_ibfk_3` FOREIGN KEY (`id_train`) REFERENCES `Train` (`id_train`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `flight_ibfk_4` FOREIGN KEY (`number_train`) REFERENCES `Train` (`number_train`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `flight_ibfk_5` FOREIGN KEY (`city_1`) REFERENCES `City` (`name_city`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `flight_ibfk_6` FOREIGN KEY (`station_1`) REFERENCES `Station` (`name_station`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `flight_ibfk_7` FOREIGN KEY (`station_2`) REFERENCES `Station` (`name_station`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `flight_ibfk_8` FOREIGN KEY (`city_2`) REFERENCES `City` (`name_city`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Ограничения внешнего ключа таблицы `Number_seats`
--
ALTER TABLE `Number_seats`
  ADD CONSTRAINT `number_seats_ibfk_1` FOREIGN KEY (`id_flight`) REFERENCES `Flight` (`id_flight`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `number_seats_ibfk_2` FOREIGN KEY (`id_class`) REFERENCES `Class` (`id_class`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Ограничения внешнего ключа таблицы `Station`
--
ALTER TABLE `Station`
  ADD CONSTRAINT `station_ibfk_1` FOREIGN KEY (`id_city`) REFERENCES `City` (`id_city`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Ограничения внешнего ключа таблицы `Ticket`
--
ALTER TABLE `Ticket`
  ADD CONSTRAINT `ticket_ibfk_1` FOREIGN KEY (`id_client`) REFERENCES `Client` (`id_client`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `ticket_ibfk_2` FOREIGN KEY (`id_flight`) REFERENCES `Flight` (`id_flight`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `ticket_ibfk_3` FOREIGN KEY (`id_class`) REFERENCES `Class` (`id_class`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Ограничения внешнего ключа таблицы `Train`
--
ALTER TABLE `Train`
  ADD CONSTRAINT `train_ibfk_1` FOREIGN KEY (`id_train_category`) REFERENCES `Train_category` (`id_train_category`) ON DELETE CASCADE ON UPDATE CASCADE;

DELIMITER $$
--
-- События
--
CREATE DEFINER=`root`@`localhost` EVENT `my_event` ON SCHEDULE EVERY 1 DAY STARTS '2024-02-10 12:11:06' ENDS '2024-12-31 23:59:59' ON COMPLETION NOT PRESERVE ENABLE DO BEGIN
    CALL procedure_update_seats_days();
    call procedure_ns_day_14();
    call update_dates();
END$$

DELIMITER ;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
