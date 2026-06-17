package com.lab.dao;

import com.lab.util.DBConnection;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

public class LoginDAO {

    public static String login(String email) {
        String sql = "SELECT userType FROM users WHERE LOWER(TRIM(email)) = LOWER(TRIM(?))";

        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, email);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getString("userType");
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        return null;
    }
}
