<%@page contentType="text/html" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>FSKM Lab Reservation</title>
    <link rel="stylesheet" type="text/css" href="${pageContext.request.contextPath}/style.css?v=20260506-auth-logo-fit">
</head>
<body class="auth-shell">
<div class="auth-layout">
    <div class="auth-brand">
        <span class="eyebrow">University Lab Room Booking System</span>
        <h1>FSKM Lab Reservation Portal</h1>
        <p class="hero-copy">
            A centralized portal for students, lecturers, and lab staff to register,
            access the system, and manage reservations more efficiently.
        </p>
        <div class="feature-stack">
            <div class="feature-card">
                <h3>Real-time availability</h3>
                <p>Check lab slots before submitting requests.</p>
            </div>
            <div class="feature-card">
                <h3>Approval workflow</h3>
                <p>Lab staff can review, approve, or reject requests in one place.</p>
            </div>
            <div class="feature-card">
                <h3>Usage reporting</h3>
                <p>Monitor the busiest labs and generate management-ready reports.</p>
            </div>
        </div>
    </div>

    <div class="auth-panel">
        <div class="portal-header">
            <span class="portal-kicker">Official FSKM Laboratory Management Portal</span>
            <img class="portal-logo" width="82" height="48" src="${pageContext.request.contextPath}/assets/Logo_Rasmi_UMT.png" alt="Universiti Malaysia Terengganu logo">
        </div>

        <%
            String mode = request.getParameter("mode");
            String message = request.getParameter("message");
            String error = request.getParameter("error");
            if (mode == null) mode = "login";
        %>

        <% if (message != null) { %>
            <div class="alert alert-success"><%= message %></div>
        <% } %>

        <% if (error != null) { %>
            <div class="alert alert-error"><%= error %></div>
        <% } %>

        <div class="toggle-container">
            <a href="index.jsp?mode=login"
               class="toggle-btn <%= mode.equals("login") ? "active" : "" %>">
               LOGIN
            </a>

            <a href="index.jsp?mode=register"
               class="toggle-btn <%= mode.equals("register") ? "active" : "" %>">
               REGISTER
            </a>
        </div>

        <% if (mode.equals("login")) { %>
        <form action="<%= request.getContextPath() %>/LoginServlet" method="POST">
            <div class="form-group">
                <label>Email</label>
                <input type="email" name="email" placeholder="student@umt.edu.my" required>
            </div>

            <div class="form-group">
                <label>Password</label>
                <input type="password" name="password" required>
                <small class="form-hint"></small>
            </div>

            <button type="submit" class="btn-login">Access Portal</button>

            <p class="footer-link">
                Need an account?
                <a href="index.jsp?mode=register">Register here</a>
            </p>
        </form>
        <% } else { %>
        <form action="<%= request.getContextPath() %>/RegisterServlet" method="POST">
            <div class="form-group">
                <label>User Type</label>
                <div class="role-picker" id="rolePicker">
                    <label class="role-card">
                        <input type="radio" name="userType" value="student" checked onchange="updateIdRequirement()">
                        <span class="role-text">
                            <strong>Student</strong>
                        </span>
                    </label>

                    <label class="role-card">
                        <input type="radio" name="userType" value="lecturer" onchange="updateIdRequirement()">
                        <span class="role-text">
                            <strong>Lecturer</strong>
                        </span>
                    </label>

                    <label class="role-card">
                        <input type="radio" name="userType" value="staff" onchange="updateIdRequirement()">
                        <span class="role-text">
                            <strong>Staff</strong>
                        </span>
                    </label>
                </div>
            </div>

            <div class="form-group">
                <label>Student / Lecturer / Staff ID</label>
                <div class="password-guide" id="idGuide">Student ID requirement: start with S followed by 5 numbers. Example: S12345</div>
                <input type="text" name="institutionId" id="institutionId" placeholder="e.g. S12345" required>
                <small class="form-hint" id="idHint">Example: S12345, L67890, or ST001.</small>
                <span class="field-error" id="institutionIdError"></span>
            </div>

            <div class="form-group">
                <label>Full Name</label>
                <input type="text" name="name" id="name" required>
                <span class="field-error" id="nameError"></span>
            </div>

            <div class="form-group">
                <label>Email</label>
                <div class="password-guide">Email requirement: must end with @umt.edu.my</div>
                <input type="email" name="email" id="email" placeholder="example@umt.edu.my" required>
                <small class="form-hint">Use your official UMT email only.</small>
                <span class="field-error" id="emailError"></span>
            </div>

            <div class="form-group">
                <label>Phone Number</label>
                <div class="password-guide">Phone number requirement: maximum 11 digits only.</div>
                <input type="text" name="phoneNum" id="phoneNum" placeholder="e.g. 0199228071" maxlength="11" required>
                <small class="form-hint">Numbers only. Maximum 11 digits.</small>
                <span class="field-error" id="phoneNumError"></span>
            </div>

            <div class="form-group">
                <label>Password</label>
                <div class="password-guide">Password requirement: at least 8 characters, with 1 letter, 1 number and 1 symbol.</div>
                <input type="password" name="password" id="password" required
                       pattern="(?=.*[A-Za-z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}"
                       title="At least 8 characters, including 1 letter, 1 number and 1 symbol">
                <small class="form-hint">Use at least 8 characters with 1 letter, 1 number and 1 symbol.</small>
                <span class="field-error" id="passwordError"></span>
            </div>

            <button type="submit" class="btn-register">Complete Registration</button>

            <p class="footer-link">
                Already have an account?
                <a href="index.jsp?mode=login">Login</a>
            </p>
        </form>

        <script>
        // ---------- INSTITUTION ID GUIDE ----------
        function updateIdRequirement() {
            const type = document.querySelector('input[name="userType"]:checked').value;
            const guide = document.getElementById('idGuide');
            const input = document.getElementById('institutionId');
            const hint = document.getElementById('idHint');

            if (type === 'student') {
                guide.textContent = 'Student ID requirement: start with S followed by 5 numbers. Example: S12345';
                input.placeholder = 'e.g. S12345';
                hint.textContent = 'Example: S12345, L67890, or ST001.';
            } else if (type === 'lecturer') {
                guide.textContent = 'Lecturer ID requirement: start with L followed by 5 numbers. Example: L67890';
                input.placeholder = 'e.g. L67890';
                hint.textContent = 'Example: S12345, L67890, or ST001.';
            } else if (type === 'staff') {
                guide.textContent = 'Staff ID requirement: start with ST followed by 3 numbers. Example: ST001';
                input.placeholder = 'e.g. ST001';
                hint.textContent = 'Example: S12345, L67890, or ST001.';
            }
            validateInstitutionId();
        }

        // ---------- REAL-TIME VALIDATION ----------
        function setError(inputId, errorId, message) {
            const input = document.getElementById(inputId);
            const error = document.getElementById(errorId);
            if (message) {
                error.textContent = message;
                input.classList.add('input-error');
            } else {
                error.textContent = '';
                input.classList.remove('input-error');
            }
        }

        function validateInstitutionId() {
            const input = document.getElementById('institutionId');
            const type = document.querySelector('input[name="userType"]:checked').value;
            const val = input.value.trim();
            if (val === '') {
                setError('institutionId', 'institutionIdError', '');
                return true;
            }
            let pattern, label;
            if (type === 'student') {
                pattern = /^[Ss]\d{5}$/;
                label = 'S followed by 5 digits (e.g. S12345)';
            } else if (type === 'lecturer') {
                pattern = /^[Ll]\d{5}$/;
                label = 'L followed by 5 digits (e.g. L67890)';
            } else {
                pattern = /^[Ss][Tt]\d{3}$/;
                label = 'ST followed by 3 digits (e.g. ST001)';
            }
            if (!pattern.test(val)) {
                setError('institutionId', 'institutionIdError', 'Institution ID must be ' + label);
                return false;
            }
            setError('institutionId', 'institutionIdError', '');
            return true;
        }

        function validateName() {
            const val = document.getElementById('name').value.trim();
            if (val === '') {
                setError('name', 'nameError', '');
                return true;
            }
            if (val.length < 2) {
                setError('name', 'nameError', 'Name must be at least 2 characters');
                return false;
            }
            setError('name', 'nameError', '');
            return true;
        }

        function validateEmail() {
            const val = document.getElementById('email').value.trim();
            if (val === '') {
                setError('email', 'emailError', '');
                return true;
            }
            if (!val.toLowerCase().endsWith('@umt.edu.my')) {
                setError('email', 'emailError', 'Email must end with @umt.edu.my');
                return false;
            }
            setError('email', 'emailError', '');
            return true;
        }

        function validatePhone() {
            const val = document.getElementById('phoneNum').value.trim();
            if (val === '') {
                setError('phoneNum', 'phoneNumError', '');
                return true;
            }
            if (!/^\d*$/.test(val)) {
                setError('phoneNum', 'phoneNumError', 'Numbers only please');
                return false;
            }
            if (val.length > 11) {
                setError('phoneNum', 'phoneNumError', 'Maximum 11 digits');
                return false;
            }
            setError('phoneNum', 'phoneNumError', '');
            return true;
        }

        function validatePassword() {
            const val = document.getElementById('password').value;
            if (val === '') {
                setError('password', 'passwordError', '');
                return true;
            }
            if (val.length < 8) {
                setError('password', 'passwordError', 'At least 8 characters');
                return false;
            }
            if (!/(?=.*[A-Za-z])(?=.*\d)(?=.*[^A-Za-z0-9])/.test(val)) {
                setError('password', 'passwordError', 'Must include 1 letter, 1 number, and 1 symbol');
                return false;
            }
            setError('password', 'passwordError', '');
            return true;
        }

        function validateAll() {
            const valid = [];
            valid.push(validateInstitutionId());
            valid.push(validateName());
            valid.push(validateEmail());
            valid.push(validatePhone());
            valid.push(validatePassword());

            // Also check empty fields
            const fields = [
                { id: 'institutionId', err: 'institutionIdError', msg: 'Institution ID is required' },
                { id: 'name', err: 'nameError', msg: 'Full name is required' },
                { id: 'email', err: 'emailError', msg: 'Email is required' },
                { id: 'phoneNum', err: 'phoneNumError', msg: 'Phone number is required' },
                { id: 'password', err: 'passwordError', msg: 'Password is required' },
            ];
            let allFilled = true;
            fields.forEach(function(f) {
                const input = document.getElementById(f.id);
                if (input.value.trim() === '') {
                    setError(f.id, f.err, f.msg);
                    allFilled = false;
                }
            });
            return valid.every(function(v) { return v; }) && allFilled;
        }

        // ---------- WIRE UP ----------
        document.addEventListener('DOMContentLoaded', function() {
            document.getElementById('institutionId').addEventListener('input', validateInstitutionId);
            document.getElementById('name').addEventListener('input', validateName);
            document.getElementById('email').addEventListener('input', validateEmail);
            document.getElementById('phoneNum').addEventListener('input', validatePhone);
            document.getElementById('password').addEventListener('input', validatePassword);

            const form = document.querySelector('form[action*="RegisterServlet"]');
            if (form) {
                form.addEventListener('submit', function(e) {
                    if (!validateAll()) {
                        e.preventDefault();
                        // Scroll to the first error
                        const firstError = form.querySelector('.input-error');
                        if (firstError) firstError.focus();
                    }
                });
            }
        });
        </script>
        <% } %>

        <div class="secure-footer">
            <p>SECURE AUTHENTICATION SYSTEM</p>
            <p>&copy; 2026 Universiti Malaysia Terengganu</p>
        </div>
    </div>
</div>
</body>
</html>
