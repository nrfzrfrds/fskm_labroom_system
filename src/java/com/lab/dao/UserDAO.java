package com.lab.dao;

import com.lab.model.User;
import com.lab.util.DBConnection;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

public class UserDAO {

    public static boolean validateUser(String email, String password) {
        String sql = "SELECT userID FROM users WHERE LOWER(TRIM(email)) = LOWER(TRIM(?)) AND TRIM(password) = TRIM(?)";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, email);
            ps.setString(2, password);

            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        return false;
    }

    public static boolean emailExists(String email) {
        String sql = "SELECT userID FROM users WHERE email=?";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, email);

            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        return false;
    }

    public static boolean insertUser(User user) {
        String sql = "INSERT INTO users(name, institutionID, email, phoneNum, userType, password) VALUES(?,?,?,?,?,?)";

        try (Connection conn = DBConnection.getConnection();
            PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, user.getName());
            ps.setString(2, user.getInstitutionId());
            ps.setString(3, user.getEmail());
            ps.setString(4, user.getPhoneNum());
            ps.setString(5, user.getUserType());
            ps.setString(6, user.getPassword());
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
        }

        return false;
    }

    public static List<User> getAllUsers() {
        List<User> users = new ArrayList<>();
        String sql = "SELECT userID, name, institutionID, email, phoneNum, userType, profilePic, password FROM users ORDER BY userID";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                users.add(mapUser(rs));
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        return users;
    }

    public static User getUserById(int userID) {
        String sql = "SELECT userID, name, institutionID, email, phoneNum, userType, profilePic, password FROM users WHERE userID=?";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, userID);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return mapUser(rs);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        return null;
    }

    public static boolean updateUser(User user) {
        String sql = "UPDATE users SET name=?, institutionID=?, email=?, phoneNum=?, userType=?, password=? WHERE userID=?";

        try (Connection conn = DBConnection.getConnection();
            PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, user.getName());
            ps.setString(2, user.getInstitutionId());
            ps.setString(3, user.getEmail());
            ps.setString(4, user.getPhoneNum());
            ps.setString(5, user.getUserType());
            ps.setString(6, user.getPassword());
            ps.setInt(7, user.getUserID());
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
        }

        return false;
    }

    public static User getUserByEmail(String email) {
        String sql = "SELECT userID, name, institutionID, email, phoneNum, userType, profilePic, password FROM users WHERE LOWER(TRIM(email)) = LOWER(TRIM(?))";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, email);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return mapUser(rs);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        return null;
    }

    public static boolean updateProfilePicture(String email, String profilePic) {
        String sql = "UPDATE users SET profilePic=? WHERE LOWER(TRIM(email)) = LOWER(TRIM(?))";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, profilePic);
            ps.setString(2, email);
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
        }

        return false;
    }

    public static boolean deleteUser(int userID) {
        String sql = "DELETE FROM users WHERE userID=?";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, userID);
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
        }

        return false;
    }

    public static int getTotalUsers() {
        String sql = "SELECT COUNT(*) FROM users";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) {
                return rs.getInt(1);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return 0;
    }

    public static int getUserCountByType(String userType) {
        String sql = "SELECT COUNT(*) FROM users WHERE userType = ?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, userType);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt(1);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return 0;
    }

    public static int getNewUsersThisMonth() {
        // Estimate: users whose userID is near the max
        String sql = "SELECT COUNT(*) FROM users WHERE userID > (SELECT COALESCE(MAX(userID) - 50, 0) FROM users)";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) {
                return rs.getInt(1);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return 0;
    }

    private static User mapUser(ResultSet rs) throws SQLException {
        User user = new User();
        user.setUserID(rs.getInt("userID"));
        user.setName(rs.getString("name"));
        user.setInstitutionId(rs.getString("institutionID"));
        user.setEmail(rs.getString("email"));
        user.setPhoneNum(rs.getString("phoneNum"));
        user.setUserType(rs.getString("userType"));
        user.setProfilePic(rs.getString("profilePic"));
        user.setPassword(rs.getString("password"));
        return user;
    }
}
