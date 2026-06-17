package com.lab.util;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.sql.Statement;

public class DBConnection {

    private static final String DB_URL
            = "jdbc:mysql://localhost:3306/lab_booking_system?createDatabaseIfNotExist=true&serverTimezone=Asia/Singapore";
    private static final String DB_USER = "root";
    private static final String DB_PASSWORD = "admin";
    private static volatile boolean schemaChecked = false;

    public static Connection getConnection() {
        Connection con = null;
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            con = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD);
            ensureSchema(con);
        } catch (Exception e) {
            e.printStackTrace();
        }
        return con;
    }

    private static void ensureSchema(Connection con) throws SQLException {
        if (schemaChecked) {
            return;
        }

        synchronized (DBConnection.class) {
            if (schemaChecked) {
                return;
            }

            createUsersTableIfMissing(con);
            ensureProfilePicColumn(con);
            createTablesIfMissing(con);

            try (Statement statement = con.createStatement()) {
                statement.executeQuery("SELECT 1 FROM users LIMIT 1");
                schemaChecked = true;
            } catch (SQLException e) {
                if (isUsersTableMissingOrBroken(e)) {
                    rebuildUsersTable(con);
                    schemaChecked = true;
                    return;
                }
                throw e;
            }
        }
    }

    private static void createTablesIfMissing(Connection con) throws SQLException {
        try (Statement statement = con.createStatement()) {
            // lab_rooms
            statement.executeUpdate(
                "CREATE TABLE IF NOT EXISTS lab_rooms ("
                + "room_id INT NOT NULL AUTO_INCREMENT,"
                + "name VARCHAR(100) NOT NULL,"
                + "PRIMARY KEY (room_id)"
                + ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4"
            );

            // lab_schedules
            statement.executeUpdate(
                "CREATE TABLE IF NOT EXISTS lab_schedules ("
                + "schedule_id INT NOT NULL AUTO_INCREMENT,"
                + "room_id INT NOT NULL,"
                + "day_of_week INT NOT NULL,"
                + "start_time TIME NOT NULL,"
                + "end_time TIME NOT NULL,"
                + "subject_info VARCHAR(255) DEFAULT NULL,"
                + "tahun INT DEFAULT NULL,"
                + "PRIMARY KEY (schedule_id),"
                + "KEY fk_room_id (room_id)"
                + ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4"
            );

            // bookings
            statement.executeUpdate(
                "CREATE TABLE IF NOT EXISTS bookings ("
                + "bookingID INT NOT NULL AUTO_INCREMENT,"
                + "dates DATE NOT NULL,"
                + "selectedRoom VARCHAR(100) NOT NULL,"
                + "userId INT NOT NULL,"
                + "userType VARCHAR(20) NOT NULL,"
                + "startTime TIME NOT NULL,"
                + "endTime TIME NOT NULL,"
                + "purpose VARCHAR(255) NOT NULL,"
                + "status VARCHAR(20) NOT NULL DEFAULT 'pending',"
                + "PRIMARY KEY (bookingID)"
                + ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4"
            );
        }
    }

    private static void createUsersTableIfMissing(Connection con) throws SQLException {
        try (Statement statement = con.createStatement()) {
            statement.executeUpdate(
                    "CREATE TABLE IF NOT EXISTS users ("
                    + "userID INT NOT NULL AUTO_INCREMENT,"
                    + "name VARCHAR(100) NOT NULL,"
                    + "institutionID VARCHAR(50) NOT NULL DEFAULT '',"
                    + "email VARCHAR(120) NOT NULL,"
                    + "phoneNum VARCHAR(20) NOT NULL,"
                    + "userType VARCHAR(20) NOT NULL,"
                    + "profilePic VARCHAR(255) DEFAULT NULL,"
                    + "password VARCHAR(255) NOT NULL,"
                    + "PRIMARY KEY (userID),"
                    + "UNIQUE KEY uq_users_email (email)"
                    + ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4"
            );
        }
    }

    private static void ensureProfilePicColumn(Connection con) throws SQLException {
        try (Statement statement = con.createStatement()) {
            statement.executeUpdate("ALTER TABLE users ADD COLUMN profilePic VARCHAR(255) DEFAULT NULL");
        } catch (SQLException e) {
            if (e.getErrorCode() != 1060) {
                throw e;
            }
        }
    }

    private static void rebuildUsersTable(Connection con) throws SQLException {
        try (Statement statement = con.createStatement()) {
            try {
                statement.executeUpdate("DROP TABLE IF EXISTS users");
            } catch (SQLException ignored) {
                // Ignore drop failures and rely on the create statement below.
            }
        }

        createUsersTableIfMissing(con);
    }

    private static boolean isUsersTableMissingOrBroken(SQLException e) {
        return e.getErrorCode() == 1146
                || e.getErrorCode() == 1932
                || (e.getMessage() != null
                && e.getMessage().toLowerCase().contains("users")
                && e.getMessage().toLowerCase().contains("doesn't exist"));
    }
}
