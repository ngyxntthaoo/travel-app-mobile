import math
import random
import time

def haversine(lat1, lon1, lat2, lon2):
    R = 6371.0
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    a = math.sin(dlat / 2)**2 + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dlon / 2)**2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return R * c

def optimize_route(places):
    if len(places) < 2: return places
    result = [places[0]]
    remaining = places[1:]
    
    while remaining:
        curr = result[-1]
        remaining.sort(key=lambda p: haversine(curr[0], curr[1], p[0], p[1]))
        result.append(remaining.pop(0))
    return result

def route_dist(places):
    total = 0.0
    for i in range(len(places) - 1):
        total += haversine(places[i][0], places[i][1], places[i+1][0], places[i+1][1])
    return total

print('### Benchmark Results\n')
print('#### 1. Đánh giá thuật toán Route Optimization (Nearest Neighbor + Haversine)')
print('| Số địa điểm | Quãng đường ban đầu (km) | Quãng đường sau tối ưu (km) | % Cải thiện | Thời gian chạy (ms) |')
print('|---|---|---|---|---|')

counts = [10, 30, 50, 100]
random.seed(42)

for count in counts:
    places = [(-8.5 + (random.random() - 0.5), 115.2 + (random.random() - 0.5)) for _ in range(count)]
    current_dist = route_dist(places)
    
    start = time.time()
    optimized = optimize_route(places)
    end = time.time()
    
    opt_dist = route_dist(optimized)
    improve = (current_dist - opt_dist) / current_dist * 100 if current_dist > 0 else 0
    ms = (end - start) * 1000
    print(f'| {count} | {current_dist:.2f} | {opt_dist:.2f} | {improve:.1f}% | {ms:.2f} ms |')


def simplify_debts(expenses):
    balances = {}
    for paid_by, splits, amount in expenses:
        balances[paid_by] = balances.get(paid_by, 0) + amount
        per_person = amount / len(splits)
        for p in splits:
            balances[p] = balances.get(p, 0) - per_person
            
    creditors = {k: v for k, v in balances.items() if v > 0.01}
    debtors = {k: -v for k, v in balances.items() if v < -0.01}
    
    sorted_creditors = sorted(creditors.items(), key=lambda x: x[1], reverse=True)
    sorted_debtors = sorted(debtors.items(), key=lambda x: x[1], reverse=True)
    
    transactions = []
    i, j = 0, 0
    while i < len(sorted_creditors) and j < len(sorted_debtors):
        cred = sorted_creditors[i]
        debt = sorted_debtors[j]
        
        amt = min(cred[1], debt[1])
        transactions.append((debt[0], cred[0], amt))
        
        sorted_creditors[i] = (cred[0], cred[1] - amt)
        sorted_debtors[j] = (debt[0], debt[1] - amt)
        
        if sorted_creditors[i][1] < 0.01: i += 1
        if sorted_debtors[j][1] < 0.01: j += 1
    return transactions, balances

print('\n#### 2. Đánh giá thuật toán Simplify Debts (Đồ thị có hướng)')
print('| Số giao dịch gốc | Số người tham gia | Số giao dịch sau khi rút gọn | Thời gian chạy (ms) | Check số dư |')
print('|---|---|---|---|---|')

exp_counts = [10, 50, 100, 500]
for count in exp_counts:
    num_people = max(3, count // 5)
    people = [f"P{i}" for i in range(num_people)]
    
    expenses = []
    for _ in range(count):
        payer = random.choice(people)
        split_count = random.randint(1, num_people)
        splits = random.sample(people, split_count)
        amt = random.random() * 1000 + 10
        expenses.append((payer, splits, amt))
        
    start = time.time()
    txs, exp_bals = simplify_debts(expenses)
    end = time.time()
    
    actual_bals = {}
    for f, t, a in txs:
        actual_bals[t] = actual_bals.get(t, 0) + a
        actual_bals[f] = actual_bals.get(f, 0) - a
        
    ok = True
    for p in people:
        if abs(exp_bals.get(p, 0) - actual_bals.get(p, 0)) > 0.05:
            ok = False
            
    ms = (end - start) * 1000
    print(f'| {count} | {num_people} | {len(txs)} | {ms:.2f} ms | {"✅ PASSED" if ok else "❌ FAILED"} |')
