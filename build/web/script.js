let startTime = null;
let endTime = null;

function resetSelection() {
    startTime = null;
    endTime = null;
    document.querySelectorAll('#time button').forEach(btn => {
        btn.classList.remove('selected');
    });
    const startInput = document.querySelector('input[name="startTime"]');
    const endInput = document.querySelector('input[name="endTime"]');
    if (startInput)
        startInput.value = '';
    if (endInput)
        endInput.value = '';
}

function showAlert(type, message) {
    var old = document.getElementById('custom-alert');
    if (old)
        old.remove();

    var config = {
        success: {
            bg: '#e5f7eb',
            border: '#13683a',
            iconBg: '#dff4e7',
            icon: '✅',
            title: 'Booking successfull!',
            titleColor: '#13683a'
        },
        warning: {
            bg: '#fff4d7',
            border: '#9b6700',
            iconBg: '#fff4d7',
            icon: '⚠️',
            title: 'Warning',
            titleColor: '#9b6700'
        },
        error: {
            bg: '#fde9e9',
            border: '#a12727',
            iconBg: '#fde9e9',
            icon: '❌',
            title: 'Error',
            titleColor: '#a12727'
        }
    };
    var c = config[type];

    var overlay = document.createElement('div');
    overlay.id = 'custom-alert';
    overlay.style.cssText =
            'position:fixed;inset:0;background:rgba(8,58,120,0.25);z-index:9999;' +
            'display:flex;align-items:center;justify-content:center;';

    var lines = message.split('\n').map(function (l) {
        return '<p style="margin:4px 0;font-size:0.9rem;color:#243447;line-height:1.5;">' + l + '</p>';
    }).join('');

    var box = document.createElement('div');
    box.style.cssText =
            'background:#ffffff;' +
            'border-radius:8px;' +
            'padding:0;' +
            'max-width:400px;width:90%;' +
            'box-shadow:0 16px 38px rgba(24,55,91,0.18);' +
            'overflow:hidden;' +
            'font-family:Segoe UI,Tahoma,Geneva,Verdana,sans-serif;';

    box.innerHTML =
            // Header bar
            '<div style="background:' + c.bg + ';border-bottom:1px solid ' + c.border + '20;' +
            'padding:1.2rem 1.5rem;display:flex;align-items:center;gap:12px;">' +
            '<span style="font-size:1.5rem;">' + c.icon + '</span>' +
            '<span style="font-size:1rem;font-weight:800;color:' + c.titleColor + ';letter-spacing:0.01em;">' + c.title + '</span>' +
            '</div>' +
            // Body
            '<div style="padding:1.2rem 1.5rem;">' +
            lines +
            '</div>' +
            // Footer
            '<div style="padding:0.8rem 1.5rem 1.2rem;display:flex;justify-content:flex-end;">' +
            '<button onclick="document.getElementById(\'custom-alert\').remove()" ' +
            'style="padding:9px 24px;background:#0b4ea2;color:#ffffff;' +
            'border:none;border-radius:6px;font-size:0.9rem;font-weight:800;' +
            'cursor:pointer;transition:background 0.2s;" ' +
            'onmouseover="this.style.background=\'#083a78\'" ' +
            'onmouseout="this.style.background=\'#0b4ea2\'">OK</button>' +
            '</div>';

    overlay.appendChild(box);
    overlay.addEventListener('click', function (e) {
        if (e.target === overlay)
            overlay.remove();
    });
    document.body.appendChild(overlay);
}

document.addEventListener('DOMContentLoaded', function () {

    const labCards = document.querySelectorAll('.lab-card');
    const selectedRoomInput = document.getElementById('selectedRoom');
    const dateInput = document.getElementById('dates');
    let unavailableData = [];

    if (dateInput) {
        const today = new Date().toISOString().split('T')[0];
        dateInput.min = today;
        dateInput.addEventListener('change', () => {
            markUnavailableSlots();
        });
    }

    labCards.forEach(card => {
        card.querySelector('button').addEventListener('click', () => {
            const room = card.getAttribute('data-room');
            selectedRoomInput.value = room;
            labCards.forEach(c => c.classList.remove('selected'));
            card.classList.add('selected');
            fetchUnavailable(room);
        });
    });

    function fetchUnavailable(room) {
        unavailableData = [];
        markUnavailableSlots();

        const formAction = document.querySelector('form').getAttribute('action');
        const url = `${formAction}?selectedRoom=${encodeURIComponent(room)}`;
        fetch(url)
                .then(res => res.json())
                .then(data => {
                    unavailableData = data;
                    if (dateInput && dateInput.value) {
                        markUnavailableSlots();
                    }
                })
                .catch(err => console.error('Fetch error:', err));
    }

    function timeToMinutes(t) {
        if (!t)
            return 0;
        const parts = t.split(':').map(Number);
        return parts[0] * 60 + (parts[1] || 0);
    }

    function markUnavailableSlots() {
        const selectedDate = dateInput ? dateInput.value : null;
        document.querySelectorAll('#time button').forEach(btn => {
            btn.classList.remove('unavailable');
            btn.disabled = false;
            if (!selectedDate)
                return;
            const slotTime = btn.getAttribute('data-time');
            if (!slotTime)
                return;
            const slotMinutes = timeToMinutes(slotTime);
            const isUnavailable = unavailableData.some(b => {
                const bookingDate = b.dates ? b.dates.substring(0, 10) : '';
                if (bookingDate !== selectedDate)
                    return false;
                const bookedStart = timeToMinutes(b.startTime);
                const bookedEnd = timeToMinutes(b.endTime);
                return slotMinutes >= bookedStart && slotMinutes <= bookedEnd;
            });
            if (isUnavailable) {
                btn.classList.add('unavailable');
                btn.disabled = true;
            }
        });
    }

    // ── Purpose "others" toggle ──
    const purposeSelect = document.getElementById('purposeSelect');
    const otherWrapper = document.getElementById('otherPurposeWrapper');
    const otherTextarea = document.getElementById('otherPurpose');

    if (purposeSelect) {
        purposeSelect.addEventListener('change', function () {
            if (this.value === 'others') {
                otherWrapper.style.display = 'block';
                otherTextarea.required = true;
            } else {
                otherWrapper.style.display = 'none';
                otherTextarea.required = false;
                otherTextarea.value = '';
            }
        });
    }

    // ── Time slot selection ──
    const buttons = document.querySelectorAll('#time button');
    const startInput = document.querySelector('input[name="startTime"]');
    const endInput = document.querySelector('input[name="endTime"]');

    function updateSelectedButtons() {
        document.querySelectorAll('#time button').forEach(btn => {
            btn.classList.remove('selected');
        });
        document.querySelectorAll('#time button').forEach(btn => {
            const t = btn.getAttribute('data-time');
            if (t === startTime || (endTime && t === endTime)) {
                btn.classList.add('selected');
            }
        });
    }

    function showSelectedTime() {
        startInput.value = startTime || '';
        endInput.value = endTime || '';
        updateSelectedButtons();
    }

    buttons.forEach(btn => {
        btn.addEventListener('click', () => {
            if (btn.classList.contains('unavailable'))
                return;
            const clickedTime = btn.getAttribute('data-time');
            if (!clickedTime)
                return;

            if (startTime === null) {
                startTime = clickedTime;
                endTime = null;
            } else if (endTime === null) {
                if (timeToMinutes(clickedTime) > timeToMinutes(startTime)) {
                    endTime = clickedTime;
                } else {
                    startTime = clickedTime;
                    endTime = null;
                }
            } else {
                startTime = clickedTime;
                endTime = null;
            }
            showSelectedTime();
        });
    });

    // ── Form validation & submit ──
    document.querySelector('form').addEventListener('submit', function (e) {
        e.preventDefault();

        const room = selectedRoomInput.value;
        const date = dateInput ? dateInput.value : '';
        const startTimeVal = startInput ? startInput.value : '';
        const endTimeVal = endInput ? endInput.value : '';
        const purpose = purposeSelect ? purposeSelect.value : '';
        const otherPurposeVal = otherTextarea ? otherTextarea.value.trim() : '';

        if (!room) {
            showAlert('warning', 'Please select a lab.');
            return;
        }
        if (!date) {
            showAlert('warning', 'Please select booking date.');
            return;
        }
        if (!startTimeVal) {
            showAlert('warning', 'Please select the start slot.');
            return;
        }
        if (!endTimeVal) {
            showAlert('warning', 'Please select the finish slot.');
            return;
        }
        if (!purpose || purpose === 'Select purpose') {
            showAlert('warning', 'Please select booking purpose.');
            return;
        }
        if (purpose === 'others' && !otherPurposeVal) {
            showAlert('warning', 'Please select booking purpose');
            return;
        }

        // Semua lengkap — submit terus
        this.submit();
    });

});